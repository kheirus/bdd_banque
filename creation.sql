

----------CREATION DES TABLE DE LA BASE BANQUE-------------

CREATE TABLE t_banque (
code_banque VARCHAR NOT NULL,
nom_banque VARCHAR(30) NOT NULL,
code_agence VARCHAR(20) NOT NULL,
PRIMARY KEY (code_banque)
);


CREATE TABLE t_compte (
num_compte NUMERIC NOT NULL,
RIB NUMERIC (22) NOT NULL UNIQUE, --22 NUM
IBAN VARCHAR (9) NOT NULL UNIQUE,
BIC VARCHAR (11) NOT NULL UNIQUE,
code_banque VARCHAR NOT NULL,
solde NUMERIC (15,2) DEFAULT 0,
decouvert NUMERIC (5,2) DEFAULT 400,
type_compte BOOLEAN DEFAULT TRUE, -- compte avec ou sans paiement (TRUE, FALSE)
FOREIGN KEY (code_banque) REFERENCES t_banque (code_banque),
PRIMARY KEY (num_compte)
);

CREATE TABLE t_client (
id_client SERIAL NOT NULL,
nom VARCHAR(30) NOT NULL,
prenom VARCHAR(30) NOT NULL,
adresse VARCHAR (150),
date_naissance DATE, 
PRIMARY KEY (id_client),
CHECK (current_date-date_naissance > integer'18')
);


--relation entre Compte et Client
CREATE TABLE r_client_compte (
id_client INT NOT NULL,
num_compte NUMERIC NOT NULL,
mandataire INT NOT NULL, --par defaut id_client
date_creation DATE DEFAULT CURRENT_DATE,
date_fermeture DATE DEFAULT '2099-12-31',
FOREIGN KEY (id_client) REFERENCES t_client (id_client),
FOREIGN KEY (num_compte) REFERENCES t_compte (num_compte),
PRIMARY KEY (id_client,num_compte)
);


-- relation entre plusieurs Comptes
CREATE TABLE r_virement (
id_virement SERIAL NOT NULL,
num_compte_creditaire NUMERIC NOT NULL,
IBAN_benificiaire VARCHAR (9) NOT NULL,
BIC_benificiaire VARCHAR (11) NOT NULL,
type_virement CHAR (1) CHECK (type_virement IN ('U','P')), -- (UNIQUE,PERMANENT)
montant_virement NUMERIC (15,2) NOT NULL,
periode CHAR (1) CHECK (periode IN('M','T','S','A')) DEFAULT NULL, --(Monsuel,Trimestriel,Semestriel,Annuel)
--periode_date INT, --PREMIER DU MOIS, TOUT LES 0501 (=5 JANVIER)..
date_virement DATE DEFAULT current_date,
FOREIGN KEY (IBAN_benificiaire) REFERENCES t_compte (IBAN),
FOREIGN KEY (BIC_benificiaire) REFERENCES t_compte (BIC),
PRIMARY KEY (id_virement,num_compte_creditaire)
);


CREATE TABLE t_interdit_bancaire (
banque VARCHAR DEFAULT current_user,
id_client INT PRIMARY KEY,
motif VARCHAR,
date_interdit DATE,
date_regularisation DATE DEFAULT NULL,
FOREIGN KEY (id_client) REFERENCES t_client (id_client)
);


CREATE TABLE t_cal (
date_cal DATE DEFAULT current_date
);



CREATE TABLE t_archive(
num_compte NUMERIC,
type_op CHAR, --VIREMENT OU OPERATION (DEPOT/RETRAIT)
montant NUMERIC, 
solde NUMERIC, 
date_operation TIMESTAMP
);


------ CREATION DE LA VUE QUI RESUME L'ENSEMBLE DU COMPTE---------------
CREATE VIEW v_compte AS SELECT * FROM t_client NATURAL JOIN r_client_compte NATURAL JOIN t_compte;
