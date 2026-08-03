# Kunden-Deployment-Checkliste

Diese Checkliste richtet eine eigene DREI-Asset-Review-Instanz für einen Kunden ein. Sie enthält bewusst keine Zugangsdaten, Tokens oder echten E-Mail-Adressen.

## Vorbereitungen

- Eigenes Repository, eigene Domain und eigener VPS-/Compose-Projektname festlegen. Bei mehreren Kunden auf demselben Docker-/Traefik-Host müssen die Traefik-Router- und Service-Labelnamen je Kunde eindeutig parametrisiert werden; die aktuellen festen Namen sind nur für einen eigenen Host sicher.
- Eigene PostgreSQL- und Active-Storage-Volumes anlegen; niemals Volumes zwischen Kunden teilen.
- Eine neue, unversionierte `.env.production` aus `.env.production.example` erstellen und alle Secret-Werte ausschließlich dort setzen.
- TLS/Reverse-Proxy für die Kundendomain konfigurieren und den `/up`-Healthcheck öffentlich erreichbar machen.
- Für Postmark einen eigenen Server oder mindestens einen strikt getrennten Message Stream verwenden; Domain, DKIM und Return-Path verifizieren.

## Erster Start

1. Den freigegebenen `main`-Commit auschecken und den Production-Stack bauen/starten.
2. Alle Migrationen ausführen lassen und nur den Containerstatus sowie `/up` prüfen.
3. Den ersten Admin sicher anlegen; Zugangsdaten nicht im Repository, Terminal-Output oder Handoff dokumentieren.
4. Eine Testmail nur an eine ausdrücklich freigegebene eigene Adresse senden und Verarbeitung/Zustellung in Postmark bestätigen.
5. Einen temporären Client über den echten Invite-Flow testen; Anmeldung, Kartenrechte und Passwortwechsel prüfen; Testkonto anschließend gezielt entfernen.

## Betrieb und Wiederherstellbarkeit

- Den täglichen lokalen PostgreSQL-Backup-Timer aktivieren und einen erfolgreichen Lauf protokollieren.
- Einen Restore in dem isolierten Restore-Stack mit einem Testdump durchführen; niemals auf der laufenden Produktionsdatenbank testen.
- Ein Offsite-Backup-Ziel mit separaten, minimalen Schreibrechten einrichten. Aufbewahrung, Verschlüsselung, Kosten, geografischer Standort und Restore-Verantwortung vorab festlegen.
- Logs und Mail-Queue datensparsam überwachen. Keine Inhalte, Passwörter oder Tokens in Tickets und Dokumentation kopieren.

## Freigabe vor Kundenstart

- Vollständige Test-Suite, Browser-Systemtests, Brakeman und Dependency-Audit grün.
- Unabhängiges `QA & Review` hat ein ausdrückliches Go erteilt.
- Diff- und Secret-Prüfung sind sauber.
- Production-Container gesund, `/up` liefert `200`, Backup ist nachweislich aktiv.
- Postmark nicht mehr im Testmodus, falls externe Kundendomains eingeladen werden sollen.
- Kunde, Datenverantwortung, Incident-Kontakt und Backup-/Restore-Verantwortung sind benannt.
