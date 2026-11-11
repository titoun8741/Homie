# Mettre Homie en ligne avec les comptes

## 1. Créer le projet Supabase
1. Sur supabase.com, crée un nouveau projet nommé **Homie**.
2. Ouvre **SQL Editor** → **New query**, colle tout le fichier `supabase-setup.sql` et clique **Run**.

## 2. Connexion par email + mot de passe
Dans **Authentication → Sign In / Providers → Email** :
- vérifie que **Email** est activé ;
- **désactive « Confirm email »** (sinon Supabase enverrait un email de confirmation avant de pouvoir se connecter).

Aucun modèle d'email ni service d'envoi n'est nécessaire.

Mot de passe oublié ? Dans **Authentication → Users**, clique sur l'utilisateur → **Delete user**, puis recrée le compte avec le même email.
Attention : son lien avec votre espace sera perdu ; il faudra rejoindre à nouveau avec le code d'invitation (visible dans les Réglages de l'autre téléphone tant qu'une place est libre).

## 3. Brancher l'appli
Dans **Project Settings → API**, copie :
- **Project URL**
- la clé **anon / public**

Colle-les dans `config.js`. Ne mets jamais la clé `service_role`.

## 4. Publier sur GitHub Pages
1. Crée un dépôt public **Homie** sur GitHub.
2. Dépose tous les fichiers (garde le dossier `icons`). `supabase-setup.sql` et `GUIDE.md` peuvent rester, ils ne gênent pas.
3. **Settings → Pages** : branche `main`, dossier `/ (root)`.
4. Dans Supabase, **Authentication → URL Configuration** : mets l'adresse GitHub Pages dans **Site URL**.

## 5. Installer et se connecter
1. Ouvre le lien dans Safari → Partager → **Sur l'écran d'accueil**.
2. Ouvre Homie depuis l'écran d'accueil → **Créer un compte** avec ton email et un mot de passe.
3. **Créer notre espace** → à la fin, un code d'invitation `HOMIE-XXXXXX` s'affiche.
4. Ton copain installe Homie, crée son compte, choisit **J'ai un code d'invitation** et entre ce code.
