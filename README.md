# Personbruker Felles Workflows

#### Dette prosjektet brukes til å definere og distribuere sentralt definerte workflows til andre repoer.
#### Dette prosjektet er en klone av pb-workflow-authority, og er ment for apper som bl. annet krever java 8.

## Bruk

- Legg til workflow-filen du ønsker å distribuere i .github/workflows mappen prefikset med '__DISTRIBUTED_'
- Bestem team, inkluderte og ekskluderte repositories i distribute_on_dispatch.yml filen
- Skriptet vil distribuere workflows til alle teamets prosjekter, pluss de som er inkludert ved siden av, minus de ekskluderte. Ekskluderte repoer tar høyest presedens.
- Distribusjon startes av et repository-dispatch kall
- Dersom DRY_RUN settes til "true," vil skriptet kun printe ut hvilke endringer det ville gjort


## Bemerkelser

- Sletting av workflows gjøres ved å legge til workflow-filnavnet (uten __DISTRIBUTED_) i config/workflow_files_to_delete.conf
  Vær varsom på at dette så lenge filnavnet finnes i denne config-filen, vil denne filen alltid slettes fra destinasjons-repoet,
  selv om filen ikke ble opprettet av pb-workflow-authority i utgangspunktet.
- Renaming av filer kan gjøres ved å rename __DISTRIBUTED_ filen og så markere det gamle filnavnet for sletting som forklart over.
  

- Workflows som trigges av push til master/main bør ha et filter på workflow-mappen, slik at man evt. ikke starter prodsetting ved push av workflow.

# Henvendelser

Spørsmål knyttet til koden eller prosjektet kan rettes mot https://github.com/orgs/navikt/teams/personbruker

## For NAV-ansatte

Interne henvendelser kan sendes via Slack i kanalen #team-personbruker.
