PatchManagement-PowerShell
Projet pédagogique de gestion et d'audit des mises à jour Windows à l'aide de PowerShell.
Objectif
Automatiser l'inventaire de postes Windows, recenser les correctifs visibles via Get-HotFix, comparer cet inventaire à une liste de KB requises, générer un rapport de sécurité et signaler les anomalies par courrier électronique dans un environnement de test.
Environnement de test
- PC-HOTE : ordinateur physique Windows 11 Famille, utilisé pour l'administration et l'exécution locale des scripts.
- PC01 : machine virtuelle Windows 11 Professionnel sous VMware, administrée à distance via PowerShell Remoting / WinRM.
- Réseau VMware NAT ; la liste des postes figure dans computers.txt.
- Mailpit : serveur SMTP local de test, sur 127.0.0.1:1025, avec interface web sur http://127.0.0.1:8025.
Les adresses IP et les noms des machines sont propres à l'environnement de démonstration et doivent être adaptés sur un autre ordinateur.
Fichiers sources
Fichier	Fonction
Check-Computers.ps1	Vérifie la disponibilité des postes listés dans computers.txt.
Inventory.ps1	Collecte les informations système et produit Inventory.csv.
PatchesInventory.ps1	Recense les correctifs et produit PatchesInventory.csv.
Compliance.ps1	Compare les KB recensées avec la liste requise et produit ComplianceReport.csv.
SecurityReport.ps1	Assemble les résultats, affiche une synthèse, produit SecurityReport.html et écrit dans PatchManager.log.
Notification.ps1	Prépare une notification lorsqu'une anomalie est détectée et l'envoie au serveur Mailpit avec le rapport HTML en pièce jointe.
computers.txt	Liste des postes et de leurs adresses IP, séparés par ;.
required-patches.txt	Liste de KB exigées par la politique de test (une KB par ligne).


Prérequis
- Windows et Windows PowerShell avec les commandes Get-CimInstance, Get-HotFix et Get-Service.
- Autorisations nécessaires pour interroger les postes et utiliser PowerShell Remoting.
- WinRM opérationnel sur les postes distants, connectivité réseau et règles de pare-feu appropriées.
- Un compte autorisé à effectuer l'inventaire à distance. Les identifiants sont demandés pendant l'exécution ; ne jamais placer un mot de passe dans le dépôt.
- Mailpit lancé localement pour la démonstration de l'envoi de notification SMTP.
Configuration
1. Placer les scripts et les fichiers .txt dans C:\PatchManagement (chemin actuellement utilisé par les scripts).
2. Adapter computers.txt au réseau de test, par exemple :
   PC-HOTE;192.168.200.1
   PC01;192.168.200.138
3. Adapter required-patches.txt à une politique de test, par exemple :
   KB5127648
   KB5127647
   KB5124007
4. Vérifier les chemins, adresses IP et nom du compte distant éventuellement écrits en dur dans les scripts avant une utilisation sur un autre environnement.
5. Dans une session PowerShell dédiée aux tests et si la politique locale l'autorise, permettre l'exécution des scripts pour cette session seulement :
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   Ce réglage temporaire ne doit pas être utilisé pour contourner les règles de sécurité d'un environnement professionnel.
Exécution
Depuis PowerShell, dans le dossier du projet :
cd C:\PatchManagement
.\Check-Computers.ps1
.\Inventory.ps1
.\PatchesInventory.ps1
.\Compliance.ps1
.\SecurityReport.ps1
.\Notification.ps1
Ordre important : chaque script de traitement exploite les résultats des étapes précédentes. Les scripts sont actuellement lancés séparément ; l'orchestration complète par un script principal reste à finaliser.

Pour tester la notification avec Mailpit, démarrer le serveur dans une autre fenêtre PowerShell (avec le chemin réel d'installation) :
C:\MailpitWindows\mailpit.exe --smtp 127.0.0.1:1025 --listen 127.0.0.1:8025
Consulter ensuite http://127.0.0.1:8025. Mailpit ne distribue pas les emails sur Internet : il les intercepte localement pour les tests.
Résultats générés
- Inventory.csv : caractéristiques et état des postes.
- PatchesInventory.csv : liste des correctifs recensés, par poste.
- ComplianceReport.csv : nombre de KB requises et manquantes, état de conformité et date du contrôle.
- SecurityReport.html : rapport de synthèse lisible dans un navigateur.
- PatchManager.log : traces de la génération du rapport et des notifications.
Dans le scénario de test réalisé le 23 octobre 2026, deux postes ont été analysés ; le contrôle sur les trois KB d'exemple a donné un poste conforme et un poste non conforme, soit 50 % de conformité parmi les postes accessibles. Ces chiffres ne représentent pas une évaluation réelle du niveau de sécurité du parc.
Limites et précautions
- Get-HotFix ne répertorie pas nécessairement toutes les mises à jour Windows. L'absence d'une KB dans cette liste ne prouve pas, à elle seule, l'absence d'une protection équivalente ou d'un correctif cumulatif qui la remplace.
- Les KB de required-patches.txt constituent une politique pédagogique de test, et non un référentiel de correctifs applicables à tous les systèmes Windows.
- Les informations issues des CSV peuvent être anciennes si l'inventaire n'est pas relancé.
- Un état INACCESSIBLE peut provenir de l'arrêt de la VM, du réseau, de WinRM, des autorisations ou d'une erreur de collecte.
- Le service Windows Update (wuauserv) peut être arrêté à un instant donné sans indiquer à lui seul une anomalie.
- La configuration SMTP sans chiffrement et sans authentification est réservée au serveur Mailpit lié à 127.0.0.1 ; elle n'est pas adaptée à un serveur de messagerie public.
- Les scripts comportent encore des chemins et paramètres spécifiques à l'environnement de test. La sécurisation finale et l'automatisation intégrale restent à finaliser.
GitHub et livrables
Le projet est destiné à un dépôt GitHub privé accessible à l'enseignant. Les scripts .ps1, les configurations d'exemple et ce README constituent les fichiers sources. Éviter de versionner des mots de passe, jetons, journaux détaillés, informations personnelles ou exécutables tiers.

Livrables complémentaires prévus : rapport synthétique et vidéo commentée d'environ 15 minutes. Date limite annoncée : 31 octobre 2026.
