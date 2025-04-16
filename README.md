# Technische Dokumentation: Linux Server Administration Tool

## 1. Übersicht
Dieses Bash-Skript ermöglicht die automatisierte Ausführung von Verwaltungsskripten auf Linux-Servern verschiedener Firmen, sowohl im interaktiven als auch im nicht-interaktiven Modus.

## 2. Voraussetzungen
- Bash Shell
- SSH-Zugriff zu den Zielservern
- Konfigurierte SSH-Schlüssel für passwortlose Authentifizierung
- Ausführungsrechte für das Skript (`chmod +x linuxadmin.sh`)

## 3. Installation und Verzeichnisstruktur

```bash
/
├── linuxadmin.sh
├── hosts.ini
└── scripts/
    ├── globalscripts/
    │   └── [globale Skripte]
    └── customerscripts/
        └── [Firmenname]/
            └── [kundenspezifische Skripte]
```

### hosts.ini Format:
```
firma1-server1
firma1-server2
firma2-server1
```

## 4. Verwendung

### Interaktiver Modus:
```bash
./linuxadmin.sh
```

### Nicht-interaktiver Modus:
```bash
./linuxadmin.sh -c [FIRMA] -s [SKRIPTPFAD] (-a|-t [SERVER])
```

## 5. Befehlszeilenoptionen

- `-h, --help`: Zeigt Hilfe an
- `-c, --company`: Firma auswählen
- `-s, --script`: Skriptpfad angeben
- `-a, --all-servers`: Auf allen Servern der Firma ausführen
- `-t, --target`: Auf spezifischem Server ausführen
- `-l, --list-companies`: Verfügbare Firmen anzeigen
- `-ls, --list-scripts`: Skripte einer Firma anzeigen
- `-lsrv, --list-servers`: Server einer Firma anzeigen

## 6. Skriptformat
Ausführbare Skripte können normale Befehle oder SCP-Befehle enthalten:

```bash
# Normaler Befehl
echo "Hello World"

# SCP-Befehl Format
SCP:/lokaler/pfad:/remote/pfad
```

## 7. Beispiele

### Alle Server einer Firma auflisten:
```bash
./linuxadmin.sh -lsrv firma1
```

### Skript auf allen Servern einer Firma ausführen:
```bash
./linuxadmin.sh -c firma1 -s scripts/globalscripts/update.sh -a
```

### Skript auf einzelnem Server ausführen:
```bash
./linuxadmin.sh -c firma1 -s scripts/customerscripts/firma1/backup.sh -t firma1-server1
```

## 8. Fehlerbehandlung

- Verbindungsfehler werden protokolliert
- Nicht existierende Firmen/Server/Skripte werden erkannt
- SSH-Timeouts werden nach 5 Sekunden ausgelöst

## 9. Sicherheitshinweise

- SSH-Schlüssel müssen korrekt eingerichtet sein
- Skript muss mit Root-Rechten auf Zielservern ausgeführt werden
- Zugriff auf das Skript sollte beschränkt werden

## 10. Support
Bei Problemen prüfen Sie:
- SSH-Verbindung zu Zielservern
- Berechtigungen der Skriptdateien
- Korrekte Syntax in hosts.ini
- Vorhandensein der Skriptverzeichnisse
