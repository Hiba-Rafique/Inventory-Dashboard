# Accessories

An inventory management dashboard for accessories, built with a **Flutter** frontend and a **Node.js / Express** backend powered by **Firebase**.

## Project Structure

```
Accessories/
├── backend/          # Node.js + Express API server
│   ├── src/
│   │   ├── app.js            # Express app setup
│   │   ├── firebase.js       # Firebase Admin SDK config
│   │   ├── routes/
│   │   │   ├── categories.js # Category endpoints
│   │   │   └── materials.js  # Material/item endpoints
│   │   └── utils/            # Utility helpers
│   ├── scripts/
│   │   └── seed.js           # Database seeding script
│   ├── index.js              # Server entry point
│   └── package.json
│
└── frontend/         # Flutter mobile/web/desktop app
    └── lib/src/
        ├── app.dart           # App root widget
        ├── models/
        │   ├── category.dart      # Category model
        │   └── material_item.dart # Material item model
        ├── services/          # API service layer
        ├── state/
        │   └── inventory_store.dart # State management
        └── ui/
            └── inventory_screen.dart # Main inventory UI
```

## Tech Stack

| Layer    | Technology                          |
| -------- | ----------------------------------- |
| Frontend | Flutter (Dart), ValueNotifier, Google Fonts |
| Backend  | Node.js, Express 5, Firebase Admin  |
| Database | Firebase (Firestore)                |

## Prerequisites

- **Flutter SDK** (≥ 3.11.0)
- **Node.js** (≥ 18)
- **npm**
- A **Firebase** project with a service account key

## Getting Started

### Backend

```bash
cd backend
npm install
```

Create a `.env` file in the `backend/` directory with your configuration, then start the server:

```bash
node index.js
```

#### Seed the Database

```bash
node scripts/seed.js
```

### Frontend

```bash
cd frontend
flutter pub get
flutter run
```

## Environment Variables

The backend requires a `.env` file. See the backend configuration for the required variables. 

## License

ISC
