# Terraform — Snapshot de l'infrastructure Azure

## Objectif

Ce dépôt contient un snapshot Terraform de l'infrastructure Azure existante.
Il sert de référence pour examiner et préparer une éventuelle reconstruction future.

Le snapshot a été exporté à partir de ressources existantes.
Il ne constitue pas une procédure de déploiement validée.

## Paramètres à vérifier avant toute reconstruction

Les paramètres suivants nécessitent une attention particulière.
Ne jamais inscrire leurs secrets ou chaînes de connexion réels dans les fichiers versionnés.

1. `AzureWebJobsStorageForGitHubLogs`
   - Chaîne de connexion du compte de stockage utilisé pour les journaux des événements GitHub.
   - Valeur neutralisée dans le snapshot local.
   - À réinjecter de manière sécurisée avant une éventuelle reconstruction.

2. `GitHubWebhookSecret`
   - Secret partagé utilisé pour authentifier les requêtes du webhook GitHub.
   - Valeur neutralisée dans le snapshot local.
   - À configurer de manière sécurisée et à faire correspondre à la configuration du webhook GitHub.

3. `AzureWebJobsStorage`
   - Paramètre de stockage utilisé par Azure Functions.
   - Vérifier sa présence et son mode de configuration dans les fichiers exportés.
   - Ne pas publier de chaîne de connexion ni de clé d'accès.

## Précautions

- Ne jamais versionner de secrets, clés d'accès, chaînes de connexion ou fichiers `.tfvars` sensibles.
- Ne pas versionner l'état Terraform (`*.tfstate*`), les plans (`*.tfplan`) ni le dossier `.terraform/`.
- Examiner les fichiers exportés et leur configuration avant toute utilisation.
- Vérifier les dépendances, les paramètres applicatifs, les autorisations et les ressources ignorées par l'export.
- Ne pas exécuter `terraform apply` sans une revue explicite et complète.
- Un export Terraform n'est pas une sauvegarde complète de toutes les configurations Azure.

## État du projet

Snapshot initial en cours de revue.
Aucune reconstruction ni application Terraform n'est autorisée dans le cadre de cette étape.
