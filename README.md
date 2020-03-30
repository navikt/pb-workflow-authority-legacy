# Personbruker Felles Workflows

#### Dette prosjektet brukes til å definere og distribuere sentralt definerte workflows til andre repoer. 
#### Dette prosjektet er en klone av pb-workflow-authority, og er ment for apper som bl. annet krever java 8.

## Bruk

- Legg til workflow-filen du ønsker å distribuere i .github/workflows mappen prefikset med '__DISTRIBUTED_'
- Bestem team, inkluderte og ekskluderte repositories i distribute_on_workflows.yml filen
- Skriptet vil distribuere workflows til alle teamets prosjekter, pluss de som er inkludert ved siden av, minus de ekskluderte. Ekskluderte repoer tar høyest presedens.
- Distribusjon startes av et repository-dispatch kall
- Dersom DRY_RUN settes til "true," vil skriptet kun printe ut hvilke endringer det ville gjort


## Bemerkelser

- Workflow-filene bør ikke ende på linjeskift. Dette forhindrer at versjon-sjekken fungerer riktig.
- Sletting av workflows i andre repoer støttes ikke enda. Dette kan implementeres dersom det blir behov for det.
- Workflows som trigges av push til master bør ha et filter på workflow-mappen, slik at man evt. ikke starter prodsetting ved push av workflow.