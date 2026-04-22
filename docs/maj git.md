1. Créer la branche d’intégration basée sur main
git checkout main
git pull origin main
git checkout -b release/integration-prod
2. Fusionner les deux branches récentes

On merge d’abord la première :

git merge improving-chatbot

Puis la seconde :

git merge feature/stripe-eshop

👉 Si conflits :

# résoudre les fichiers
git add .
git commit
3. Pousser la branche d’intégration (optionnel mais recommandé)
git push origin release/integration-prod
4. Une fois validé (tests / staging), mettre à jour main
git checkout main
git pull origin main
git merge release/integration-prod
git push origin main