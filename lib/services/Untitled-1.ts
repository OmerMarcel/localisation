import mongoose from "mongoose";

export const connectDatabase = async (): Promise<void> => {
  try {
    // Utiliser l'URI du .env qui pointe vers l'instance locale existante
    const mongoUri = process.env.MONGODB_URI || "mongodb://localhost:27017/localisation_infra";
    
    await mongoose.connect(mongoUri, {
      // Options de connexion optimisées pour éviter les conflits
      maxPoolSize: 5, // Limiter le nombre de connexions
      serverSelectionTimeoutMS: 5000,
      socketTimeoutMS: 45000,
    } as mongoose.ConnectOptions);

    console.log("✅ Base de données MongoDB connectée (instance locale)");
  } catch (error) {
    console.error("❌ Erreur de connexion à MongoDB:", error);
    process.exit(1);
  }
};