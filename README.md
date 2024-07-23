# Create Users

Créer des utilisateurs sur keycloak et/ou OpenProject via ansible.

Pour chaque utilisateur, les informations suivantes sont nécessaires:

- Prénom
- Nom
- Courriel

Les utilisateurs auront tous le même mot de passe (trouvable dans le fichier `inventory/group_vars/all/vault.yml` et sur le vaultwarden), charge à eux de le modifier

Pour keycloak, le compte admin est utilisé. Pour OpenProject, un compte system bot a été créé pour l'occasion.

## Avec la CI

### Pré-requis

Sur gitlab, ajouter la variable avec les caractéristiques suivantes:

- Type: FILE
- Flags:
  - Protect variable: non
  - Mask variable: non
  - Expand variable reference: oui
- Key: ANSIBLE_VAULT_PASSWORD_FILE
- Value: voir sur le bitwarden

### Pipeline avec un fichier CSV

A partir d'un fichier CSV au format `NOM,Prénom,adresse@email.fr`, le pipeline permet de créer en batch des comptes utilisateurs sur Keycloak et/ou Openproject.
La pipeline se lance manuellement et il convient de copier le contenu du fichier CSV dans la variable `USERS`.

Par exemple avec :

```csv
MICHALAK,Christophe,christophe.michalak@patisserie.fr
HERME,Pierre,pierre.herme@patisserie.fr
```

La pipeline peut être adaptée à l'aide de certaines variables (`CSV_SEPARATOR` et `CSV_DATA_HEADER`) si vous utilisez un séparateur différent de `,` ou un header, et les variables `CREATE_KEYCLOAK_USERS` et `CREATE_OPENPROJECT_USERS` permettent de choisir sur quelles plateformes créer les comptes utilisateurs.

## Limitations

Les playbooks n'ajoutent pas les utilisateurs à des groupes/projets.

Sur keycloak, charge au propriétaire du projet d'ajouter les nouveaux utilisateurs.

Sur OpenProject, la ServiceTeam doit ajouter ces utilisateurs au bon projet.
