-- Base de données Logiloc Immo
-- Système de gestion immobilière complet

-- Création de la base de données
CREATE DATABASE IF NOT EXISTS logiloc_immo CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE logiloc_immo;

-- Table des utilisateurs
CREATE TABLE IF NOT EXISTS utilisateurs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    telephone VARCHAR(20) NOT NULL,
    password VARCHAR(255) NOT NULL,
    type_compte ENUM('client', 'proprietaire', 'admin') DEFAULT 'client',
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_type (type_compte)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table des biens meublés
CREATE TABLE IF NOT EXISTS biens (
    id INT AUTO_INCREMENT PRIMARY KEY,
    titre VARCHAR(255) NOT NULL,
    description TEXT,
    adresse VARCHAR(255) NOT NULL,
    ville VARCHAR(100) NOT NULL,
    code_postal VARCHAR(10) NOT NULL,
    pays VARCHAR(50) DEFAULT 'France',
    surface DECIMAL(6,2) NOT NULL,
    chambres INT NOT NULL,
    sdb INT NOT NULL,
    prix DECIMAL(10,2) NOT NULL,
    periode ENUM('nuit', 'semaine', 'mois') NOT NULL,
    duree ENUM('court', 'moyen', 'long') NOT NULL,
    image VARCHAR(255),
    statut ENUM('disponible', 'reserve', 'maintenance') DEFAULT 'disponible',
    proprietaire_id INT,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (proprietaire_id) REFERENCES utilisateurs(id) ON DELETE SET NULL,
    INDEX idx_statut (statut),
    INDEX idx_ville (ville),
    INDEX idx_prix (prix)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table des réservations
CREATE TABLE IF NOT EXISTS reservations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    utilisateur_id INT NOT NULL,
    bien_id INT NOT NULL,
    date_arrivee DATE NOT NULL,
    date_depart DATE NOT NULL,
    nombre_personnes INT DEFAULT 1,
    statut ENUM('en_attente', 'confirmee', 'annulee', 'terminee') DEFAULT 'en_attente',
    message TEXT,
    prix_total DECIMAL(10,2),
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
    FOREIGN KEY (bien_id) REFERENCES biens(id) ON DELETE CASCADE,
    INDEX idx_utilisateur (utilisateur_id),
    INDEX idx_bien (bien_id),
    INDEX idx_dates (date_arrivee, date_depart),
    INDEX idx_statut (statut)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table des demandes de services immobiliers
CREATE TABLE IF NOT EXISTS demandes_services (
    id INT AUTO_INCREMENT PRIMARY KEY,
    utilisateur_id INT NOT NULL,
    type_service ENUM('gestion_locative', 'transaction', 'syndic', 'evaluation', 'promotion', 'conseil') NOT NULL,
    description TEXT NOT NULL,
    statut ENUM('en_attente', 'en_cours', 'terminee', 'annulee') DEFAULT 'en_attente',
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
    INDEX idx_utilisateur (utilisateur_id),
    INDEX idx_type (type_service),
    INDEX idx_statut (statut)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table des disponibilités (pour synchronisation avec plateformes externes)
CREATE TABLE IF NOT EXISTS disponibilites (
    id INT AUTO_INCREMENT PRIMARY KEY,
    bien_id INT NOT NULL,
    date DATE NOT NULL,
    statut ENUM('disponible', 'reserve', 'bloque') DEFAULT 'disponible',
    plateforme_source VARCHAR(50) DEFAULT 'logiloc',
    id_reservation_externe VARCHAR(255),
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (bien_id) REFERENCES biens(id) ON DELETE CASCADE,
    UNIQUE KEY unique_bien_date (bien_id, date),
    INDEX idx_date (date),
    INDEX idx_bien (bien_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table des intégrations API
CREATE TABLE IF NOT EXISTS integrations_api (
    id INT AUTO_INCREMENT PRIMARY KEY,
    utilisateur_id INT,
    plateforme ENUM('google_calendar', 'airbnb', 'booking_com', 'autre') NOT NULL,
    nom_integration VARCHAR(255),
    api_key VARCHAR(255),
    api_secret VARCHAR(255),
    access_token TEXT,
    refresh_token TEXT,
    token_expiration TIMESTAMP,
    statut ENUM('active', 'inactive', 'erreur') DEFAULT 'inactive',
    derniere_synchro TIMESTAMP,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
    INDEX idx_plateforme (plateforme),
    INDEX idx_statut (statut)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table des favoris
CREATE TABLE IF NOT EXISTS favoris (
    id INT AUTO_INCREMENT PRIMARY KEY,
    utilisateur_id INT NOT NULL,
    bien_id INT NOT NULL,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
    FOREIGN KEY (bien_id) REFERENCES biens(id) ON DELETE CASCADE,
    UNIQUE KEY unique_favori (utilisateur_id, bien_id),
    INDEX idx_utilisateur (utilisateur_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table des avis
CREATE TABLE IF NOT EXISTS avis (
    id INT AUTO_INCREMENT PRIMARY KEY,
    utilisateur_id INT NOT NULL,
    bien_id INT NOT NULL,
    reservation_id INT,
    note INT NOT NULL CHECK (note >= 1 AND note <= 5),
    commentaire TEXT,
    statut ENUM('en_attente', 'publie', 'masque') DEFAULT 'en_attente',
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
    FOREIGN KEY (bien_id) REFERENCES biens(id) ON DELETE CASCADE,
    FOREIGN KEY (reservation_id) REFERENCES reservations(id) ON DELETE SET NULL,
    INDEX idx_bien (bien_id),
    INDEX idx_note (note)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table des notifications
CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    utilisateur_id INT NOT NULL,
    type ENUM('reservation', 'message', 'avis', 'systeme') NOT NULL,
    titre VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    lien VARCHAR(255),
    lue BOOLEAN DEFAULT FALSE,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
    INDEX idx_utilisateur (utilisateur_id),
    INDEX idx_lue (lue)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insertion d'un utilisateur admin par défaut
INSERT INTO utilisateurs (nom, email, telephone, password, type_compte) 
VALUES ('Administrateur', 'admin@logilocimmo.fr', '+33123456789', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin')
ON DUPLICATE KEY UPDATE email=email;

-- Insertion de biens de démonstration
INSERT INTO biens (titre, description, adresse, ville, code_postal, surface, chambres, sdb, prix, periode, duree, image, statut) VALUES
('Appartement Centre-Ville Moderne', 'Magnifique appartement meublé en plein cœur de Paris, proche de tous les commerces et transports.', '15 Rue de la République', 'Paris', '75001', 45.00, 1, 1, 85.00, 'nuit', 'court', 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=600', 'disponible'),
('Studio Quartier Latin', 'Studio charmant et fonctionnel dans le quartier historique du Latin.', '42 Boulevard Saint-Michel', 'Paris', '75005', 30.00, 1, 1, 65.00, 'nuit', 'court', 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=600', 'disponible'),
('Appartement Haussmannien', 'Superbe appartement haussmannien avec vue sur les toits de Paris.', '8 Avenue des Champs-Élysées', 'Paris', '75008', 75.00, 2, 1, 150.00, 'nuit', 'moyen', 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=600', 'disponible')
ON DUPLICATE KEY UPDATE titre=titre;
