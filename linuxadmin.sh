#!/bin/bash

# Funktion zur Anzeige der Hilfe
show_help() {
    echo "Verwendung: $0 [Optionen]"
    echo
    echo "Optionen:"
    echo "  -h, --help                 Diese Hilfenachricht anzeigen"
    echo "  -c, --company FIRMA        Firmenname auswählen"
    echo "  -s, --script SKRIPTPFAD    Pfad zum auszuführenden Skript"
    echo "  -a, --all-servers          Auf allen Servern der Firma ausführen"
    echo "  -t, --target SERVER        Auf einem bestimmten Server ausführen"
    echo "  -l, --list-companies       Verfügbare Firmen auflisten"
    echo "  -ls, --list-scripts FIRMA  Verfügbare Skripte für eine Firma auflisten"
    echo "  -lsrv, --list-servers FIRMA Verfügbare Server für eine Firma auflisten"
    echo
    echo "Ohne Parameter wird das Skript im interaktiven Modus ausgeführt."
}

# Funktion zum Auflisten der Firmen
list_companies() {
    echo "Verfügbare Firmen:"
    for i in "${!company_names[@]}"; do
        echo "$((i+1))) ${company_names[$i]}"
    done
}

# Funktion zum Auflisten der Skripte für eine Firma
list_scripts() {
    local company=$1
    
    # Sammle alle verfügbaren Skripte
    local all_scripts=()
    local script_paths=()

    # Füge globale Skripte hinzu
    if [ -d "scripts/globalscripts/" ]; then
        for script in scripts/globalscripts/*; do
            if [ -f "$script" ]; then
                script_name=$(basename "$script")
                all_scripts+=("Globales Skript: $script_name")
                script_paths+=("$script")
            fi
        done
    fi

    # Füge kundenspezifische Skripte hinzu
    if [ -d "scripts/customerscripts/$company/" ]; then
        for script in scripts/customerscripts/$company/*; do
            if [ -f "$script" ]; then
                script_name=$(basename "$script")
                all_scripts+=("Kundenspezifisches Skript: $script_name")
                script_paths+=("$script")
            fi
        done
    fi

    if [ ${#all_scripts[@]} -eq 0 ]; then
        echo "Keine Skripte für $company gefunden."
        return 1
    fi

    echo "Verfügbare Skripte für $company:"
    for i in "${!all_scripts[@]}"; do
        echo "$((i+1))) ${all_scripts[$i]} (${script_paths[$i]})"
    done
    
    return 0
}

# Funktion zum Auflisten der Server für eine Firma
list_servers() {
    local company=$1
    local filtered_servers=()
    
    for server in "${all_servers[@]}"; do
        if [[ "$server" == "$company"* ]]; then
            filtered_servers+=("$server")
        fi
    done
    
    if [ ${#filtered_servers[@]} -eq 0 ]; then
        echo "Keine Server für $company gefunden."
        return 1
    fi
    
    echo "Verfügbare Server für $company:"
    for i in "${!filtered_servers[@]}"; do
        echo "$((i+1))) ${filtered_servers[$i]}"
    done
    
    return 0
}

# Funktion zur Ausführung des Skripts auf den Servern
execute_script() {
    local script_path=$1
    local servers=("${@:2}")
    
    for server in "${servers[@]}"; do
        # Überprüfe die Verbindung
        if ssh -o BatchMode=yes -o ConnectTimeout=5 root@$server "echo 2>&1"; then
            echo -e "\nFühre Skript auf $server aus:"
            
            while IFS= read -r line || [ -n "$line" ]; do
                # Überspringe leere Zeilen
                [ -z "$line" ] && continue
                
                if [[ "$line" == SCP:* ]]; then
                    # Verarbeite SCP-Befehle
                    source_path=$(echo "$line" | cut -d':' -f2)
                    dest_path=$(echo "$line" | cut -d':' -f3)
                    
                    if [ -f "$source_path" ]; then
                        echo "Kopiere $source_path nach $server:$dest_path"
                        scp "$source_path" root@"$server":"$dest_path"
                    else
                        echo "WARNUNG: Quelldatei $source_path nicht gefunden!"
                    fi
                else
                    # Führe normale Befehle aus mit -n Option
                    echo "Führe aus: $line"
                    ssh -n root@"$server" "$line"
                fi
            done < "$script_path"
        else
            echo "Verbindung zu $server fehlgeschlagen."
        fi
    done
}

# Funktion zum Sammeln aller Skripte für eine Firma
get_scripts_for_company() {
    local company=$1
    local all_scripts=()
    local script_paths=()

    # Füge globale Skripte hinzu
    if [ -d "scripts/globalscripts/" ]; then
        for script in scripts/globalscripts/*; do
            if [ -f "$script" ]; then
                script_name=$(basename "$script")
                all_scripts+=("Globales Skript: $script_name")
                script_paths+=("$script")
            fi
        done
    fi

    # Füge kundenspezifische Skripte hinzu
    if [ -d "scripts/customerscripts/$company/" ]; then
        for script in scripts/customerscripts/$company/*; do
            if [ -f "$script" ]; then
                script_name=$(basename "$script")
                all_scripts+=("Kundenspezifisches Skript: $script_name")
                script_paths+=("$script")
            fi
        done
    fi
    
    echo "${script_paths[@]}"
}

# Funktion zum Filtern der Server nach Firma
get_servers_for_company() {
    local company=$1
    local filtered_servers=()
    
    for server in "${all_servers[@]}"; do
        if [[ "$server" == "$company"* ]]; then
            filtered_servers+=("$server")
        fi
    done
    
    echo "${filtered_servers[@]}"
}

# Lese die Serverliste aus der Datei hosts.ini
mapfile -t all_servers < hosts.ini

# Extrahiere die Firmennamen aus den Hostnamen
declare -A companies
for server in "${all_servers[@]}"; do
    company=$(echo "$server" | cut -d'-' -f1)
    companies["$company"]=1
done

# Erstelle ein Array mit den eindeutigen Firmennamen
company_names=()
for company in "${!companies[@]}"; do
    company_names+=("$company")
done

# Initialisiere Variablen für Kommandozeilenparameter
selected_company=""
selected_script=""
all_company_servers=false
selected_target=""
interactive_mode=true

# Verarbeite Kommandozeilenparameter
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -c|--company)
            selected_company="$2"
            shift 2
            ;;
        -s|--script)
            selected_script="$2"
            shift 2
            ;;
        -a|--all-servers)
            all_company_servers=true
            shift
            ;;
        -t|--target)
            selected_target="$2"
            shift 2
            ;;
        -l|--list-companies)
            list_companies
            exit 0
            ;;
        -ls|--list-scripts)
            if [[ -z "$2" ]]; then
                echo "Fehler: Firmenname für --list-scripts erforderlich"
                exit 1
            fi
            list_scripts "$2"
            exit $?
            ;;
        -lsrv|--list-servers)
            if [[ -z "$2" ]]; then
                echo "Fehler: Firmenname für --list-servers erforderlich"
                exit 1
            fi
            list_servers "$2"
            exit $?
            ;;
        *)
            echo "Unbekannte Option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Prüfe, ob wir im nicht-interaktiven Modus sind
if [[ -n "$selected_company" && ( -n "$selected_script" ) && ( "$all_company_servers" = true || -n "$selected_target" ) ]]; then
    # Nicht-interaktiver Modus
    interactive_mode=false
    
    # Prüfe, ob die Firma existiert
    company_exists=false
    for company in "${company_names[@]}"; do
        if [[ "$company" == "$selected_company" ]]; then
            company_exists=true
            break
        fi
    done
    
    if [[ "$company_exists" = false ]]; then
        echo "Fehler: Firma '$selected_company' nicht gefunden"
        exit 1
    fi
    
    # Prüfe, ob das Skript existiert
    if [[ ! -f "$selected_script" ]]; then
        echo "Fehler: Skript '$selected_script' nicht gefunden"
        exit 1
    fi
    
    # Bestimme die Server
    if [[ "$all_company_servers" = true ]]; then
        # Alle Server der Firma
        selected_servers=($(get_servers_for_company "$selected_company"))
    else
        # Einzelner Server
        server_exists=false
        for server in "${all_servers[@]}"; do
            if [[ "$server" == "$selected_target" ]]; then
                server_exists=true
                break
            fi
        done
        
        if [[ "$server_exists" = false ]]; then
            echo "Fehler: Server '$selected_target' nicht gefunden"
            exit 1
        fi
        
        selected_servers=("$selected_target")
    fi
    
    # Führe das Skript aus
    execute_script "$selected_script" "${selected_servers[@]}"
    
    exit 0
fi

# Interaktiver Modus, wenn nicht alle Parameter angegeben wurden
# Für die Ausgabe am Ende merken wir uns die gewählten Optionen
command_suggestion=""

# Wenn die Firma bereits angegeben wurde, überspringen wir die Firmenauswahl
if [[ -z "$selected_company" ]]; then
    # Frage den Benutzer, für welche Firma er arbeiten möchte
    echo "Welche Firma?"
    for i in "${!company_names[@]}"; do
        echo "$((i+1))) ${company_names[$i]}"
    done
    read -p "Bitte wähle eine Firma (Nummer): " company_option
    selected_company_index=$((company_option-1))

    if [ -z "${company_names[$selected_company_index]}" ]; then
        echo "Ungültige Auswahl. Beende das Skript."
        exit 1
    fi

    selected_company="${company_names[$selected_company_index]}"
fi

command_suggestion="$0 --company $selected_company"

# Sammle alle verfügbaren Skripte in ein gemeinsames Array
all_scripts=()
script_paths=()

# Füge globale Skripte hinzu
if [ -d "scripts/globalscripts/" ]; then
    for script in scripts/globalscripts/*; do
        # Prüfe ob die Datei existiert und eine reguläre Datei ist
        if [ -f "$script" ]; then
            script_name=$(basename "$script")
            all_scripts+=("Globales Skript: $script_name")
            script_paths+=("$script")
        fi
    done
fi

# Füge kundenspezifische Skripte hinzu
if [ -d "scripts/customerscripts/$selected_company/" ]; then
    for script in scripts/customerscripts/$selected_company/*; do
        # Prüfe ob die Datei existiert und eine reguläre Datei ist
        if [ -f "$script" ]; then
            script_name=$(basename "$script")
            all_scripts+=("Kundenspezifisches Skript: $script_name")
            script_paths+=("$script")
        fi
    done
fi

# Prüfe, ob Skripte gefunden wurden
if [ ${#all_scripts[@]} -eq 0 ]; then
    echo "Keine Skripte gefunden. Beende das Skript."
    exit 1
fi

# Wenn das Skript bereits angegeben wurde, überspringen wir die Skriptauswahl
if [[ -z "$selected_script" ]]; then
    # Zeige alle verfügbaren Skripte an
    echo -e "\nVerfügbare Skripte:"
    for i in "${!all_scripts[@]}"; do
        echo "$((i+1))) ${all_scripts[$i]}"
    done

    # Frage nach dem auszuführenden Skript
    read -p "Bitte wähle ein Skript (Nummer): " script_option
    selected_script_index=$((script_option-1))

    if [ -z "${script_paths[$selected_script_index]}" ]; then
        echo "Ungültige Auswahl. Beende das Skript."
        exit 1
    fi

    selected_script="${script_paths[$selected_script_index]}"
fi

command_suggestion="$command_suggestion --script \"$selected_script\""
echo "Ausgewähltes Skript: $(basename "$selected_script")"

# Filtere die Server nach der ausgewählten Firma
servers=()
for server in "${all_servers[@]}"; do
    if [[ "$server" == "$selected_company"* ]]; then
        servers+=("$server")
    fi
done

# Wenn bereits all_company_servers oder selected_target angegeben wurden, überspringen wir die Serverauswahl
if [[ "$all_company_servers" = true ]]; then
    selected_servers=("${servers[@]}")
    command_suggestion="$command_suggestion --all-servers"
elif [[ -n "$selected_target" ]]; then
    # Prüfe, ob der angegebene Server existiert
    server_exists=false
    for server in "${servers[@]}"; do
        if [[ "$server" == "$selected_target" ]]; then
            server_exists=true
            break
        fi
    done
    
    if [[ "$server_exists" = false ]]; then
        echo "Fehler: Server '$selected_target' nicht gefunden"
        exit 1
    fi
    
    selected_servers=("$selected_target")
    command_suggestion="$command_suggestion --target \"$selected_target\""
else
    # Frage den Benutzer, ob das Skript für alle Server oder nur für einen bestimmten ausgeführt werden soll
    echo -e "\nMöchtest du das Skript für alle Server der Firma $selected_company ausführen oder nur für einen bestimmten?"
    echo "1) Alle Server"
    echo "2) Einen bestimmten Server"
    read -p "Bitte wähle eine Option (1 oder 2): " option

    if [ "$option" -eq 1 ]; then
        selected_servers=("${servers[@]}")
        command_suggestion="$command_suggestion --all-servers"
    elif [ "$option" -eq 2 ]; then
        echo "Verfügbare Server:"
        for i in "${!servers[@]}"; do
            echo "$((i+1))) ${servers[$i]}"
        done
        read -p "Bitte wähle einen Server (Nummer): " server_option
        selected_server_index=$((server_option-1))
        if [ -z "${servers[$selected_server_index]}" ]; then
            echo "Ungültige Auswahl. Beende das Skript."
            exit 1
        fi
        selected_servers=("${servers[$selected_server_index]}")
        command_suggestion="$command_suggestion --target \"${servers[$selected_server_index]}\""
    else
        echo "Ungültige Auswahl. Beende das Skript."
        exit 1
    fi
fi

# Führe das Skript auf den ausgewählten Servern aus
execute_script "$selected_script" "${selected_servers[@]}"

# Wenn wir im interaktiven Modus sind, zeige die Kommandozeilenparameter für das nächste Mal an
if [[ "$interactive_mode" = true ]]; then
    echo -e "\n------------------------------------------------------------"
    echo "Das nächste Mal können Sie das Skript mit folgenden Parametern ausführen:"
    echo "$command_suggestion"
    echo -e "------------------------------------------------------------"
fi
