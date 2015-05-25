
\copy t_banque from banque.csv delimiter ','
INSERT INTO t_banque VALUES (current_user,'MyBank',999);
\copy t_compte (num_compte,rib,iban,bic,code_banque,solde,type_compte) from compte.csv delimiter ','
\copy t_client from client.csv delimiter ','
\copy r_client_compte (id_client,num_compte,mandataire,date_creation) from r_client_compte.csv delimiter ','
\copy r_virement from r_virement.csv delimiter ','

INSERT INTO t_interdit_bancaire VALUES 
       (DEFAULT,4,'motif 190','2011-08-16','2017-08-16'),
       (DEFAULT,6,'motif 870','2007-01-23','2012-01-23');

INSERT INTO t_cal VALUES (CURRENT_DATE);