# Middleware d'extraction du sous-domaine 
## Qu'est-ce que j'ai fait ?

J'ai implémenté un plugin Kong qui extrait automatiquement le **tenant** (nom de l'entreprise) depuis le sous-domaine de chaque requête entrante, et l'injecte dans un header `X-Subdomain` pour que les microservices puissent l'utiliser.

---

## Pourquoi ?

Woridge est une plateforme **SaaS multi-tenant**. Chaque entreprise a son propre sous-domaine :

```
company-a.woridge.com  →  tenant = company-a  →  DB woridge_company_a
company-b.woridge.com  →  tenant = company-b  →  DB woridge_company_b
```

Sans ce middleware, les microservices ne savent pas **à quelle entreprise appartient la requête**.

---

## Comment ça marche ?

```
Requête : company-a.woridge.com/api/users
                    │
                    ▼
            [ Kong Gateway ]
            Plugin Lua s'exécute
            → extrait "company-a"
            → ajoute X-Subdomain: company-a
                    │
                    ▼
          [ Microservice ]
          lit X-Subdomain: company-a
          → utilise DB woridge_company_a 
```

---

## Ce que j'ai modifié

Un seul fichier : **`kong.yaml`**

J'ai ajouté le plugin `pre-function` globalement (s'applique à toutes les routes) .



---

## Comment utiliser X-Subdomain dans votre microservice

**Spring Boot**
```java
String tenant = request.getHeader("X-Subdomain");
```

**.NET Core**
```csharp
var tenant = Request.Headers["X-Subdomain"].ToString();
```

---

## Résultats des tests

| Requête | Host | Résultat |
|---|---|---|
| GET /test | `company-a.woridge.com` |  `X-Subdomain: company-a` |
| GET /test | `company-b.woridge.com` |  `X-Subdomain: company-b` |
| GET /test | `woridge.com` |  400 Sous-domaine manquant |
| GET /test | *(pas de Host)* |  400 Header Host manquant |

---

