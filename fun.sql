---- EXECUTER LES FONCTIONS AUXILIAIRES QUI SE TROUVENT DANS fun_aux.sql
\i fun_aux.sql;	
\set VERBOSITY terse

/************************************************************************************************************************************************************************/
/*								CONSULTER SOLDE						                                                */
/************************************************************************************************************************************************************************/
CREATE OR REPLACE FUNCTION consult_solde(num NUMERIC) RETURNS NUMERIC AS $$ 
       DECLARE
       s NUMERIC;
       BEGIN       	  
       	  
       SELECT solde INTO s
       FROM t_compte 
       WHERE num_compte = num ;
       
       IF FOUND THEN
       RETURN s;
       
       ELSE RETURN 'uknown';
       END IF;
       END;
$$ LANGUAGE 'plpgsql';



/************************************************************************************************************************************************************************/
/*								OUVERTURE D'UN COMPTE					                                                */
/************************************************************************************************************************************************************************/

CREATE OR REPLACE FUNCTION f_ouverture_compte() RETURNS TRIGGER AS $tg_ouverture_compte$
      DECLARE
       n_num_compte BIGINT; 
       n_rib NUMERIC;
       n_iban VARCHAR(9);
       n_bic VARCHAR (11);
       n_solde NUMERIC;
       n_decouvert NUMERIC;
       n_type_compte BOOLEAN;
       id_interdit INT;
       id record;
       c record;
       n INT;
       BEGIN
       
       -- ON VERIFIE SI LE CLIENT N'EST PAS INTERDIT BANCAIRE
	FOR id IN
	    SELECT * FROM t_client NATURAL JOIN t_interdit_bancaire
	LOOP
		IF id.nom = NEW.nom AND id.prenom=NEW.prenom AND id.date_naissance =NEW.date_naissance THEN
 	    	   RAISE EXCEPTION 'Mr/Mme : "% %" est interdit(e) bancaire depuis "%" pour le motif suivant : "%"',upper(id.prenom),upper(id.nom),id.date_interdit,upper(id.motif); 
		  
            	END IF;	 
	         
	END LOOP;	
	
	-- ON ATTRIBUT AU NOUVAU CLIENT UN NUMERO DE COMPTE AVEC UN RIB..	

	      n_num_compte:= (random()*10000000000)::BIGINT;
       	      n_rib := (random()*10000000000000000000000)::NUMERIC;
       	      n_iban :=rstr(9);
       	      n_bic :=rstr2(11);
       	      n_solde:=0;
		INSERT INTO t_compte 
		       VALUES 
		       (
		       n_num_compte, 
		       n_rib,
		       n_iban,
		       n_bic,
       		       current_user,
       		       n_solde,
       		       DEFAULT,
       		       DEFAULT
		       );

	--- OUVERTURE DU COMPTE 	       
		INSERT INTO r_client_compte
		       VALUES
		       (NEW.id_client,
		       n_num_compte,
		       NEW.id_client,
		       current_date,
		       DEFAULT
		       );
	
	
	RAISE INFO  'NOUVEAU COMPTE CRÉÉ';
	RAISE INFO  'COMPTE NUMÉRO: %  RIB: %',n_num_compte,n_rib;
	
       	 	
       RETURN NULL;
       END;	  		
$tg_ouverture_compte$ LANGUAGE 'plpgsql';
 

/************************************************************************************************************************************************************************/
/*								 VIREMENT ENTRE COMPTES					                                                */
/************************************************************************************************************************************************************************/

CREATE OR REPLACE FUNCTION f_virement() RETURNS TRIGGER AS $tg_virement$
       DECLARE
       c INT;--CREDITAIRE
       d INT;--DEBITAIRE
       is_m BOOLEAN;
       is_i BOOLEAN;
       facturation INT;
       aj INT;
       fac INT;
       s record;
       nom_c record;
       nom_b record;
       f numeric;
       ligne record; 
       id record;
       
       BEGIN 

       	     facturation :=3;
       	     
       	     ----- POUR LE TRIGGER INSERT
       	     IF TG_OP = 'INSERT' AND 
	     (NEW.montant_virement <= 10) THEN 
	     RAISE EXCEPTION 'Montant du virement doit être au moins 10 euros';     
	     END IF;
	     
	     ----- VIREMENT UNIQUE
	     IF NEW.type_virement = 'U' THEN
	     
	     ---- ON VERIFIE QUE LE CLIENT QUI EFFECTUE LE VIREMENT EST BIEN LE MANDATAIRE DU COMPTE
	     ---- ON VERIFIE SI LE CLIENT QUI EFFECTUE LE VIREMENT N'ES PAS INTERDIT BANCAIRE	 
		  
		  is_m = is_mandataire (NEW.num_compte_creditaire);
		  is_i = is_interdit (NEW.num_compte_creditaire);
		  
		  IF is_i = TRUE  THEN
		     RAISE EXCEPTION 'VIREMENT IMPOSSIBLE';
		  END IF;
		  	
		  IF is_m = FALSE THEN
		     RAISE EXCEPTION 'VIREMENT IMPOSSIBLE';
		  END IF;
		  
		  
		  


	     ---- FAIRE LA TRANSACTION (Le code est entre BEGIN..EXCEPTION pour qu'en cas d'erreur, la trasaction est annulée)
	     BEGIN    
	     	      UPDATE t_compte SET solde = solde - NEW.montant_virement
      	     	      WHERE num_compte = NEW.num_compte_creditaire;
       	     	      
		      UPDATE t_compte SET solde = solde + NEW.montant_virement
      	     	      WHERE IBAN = NEW.IBAN_benificiaire
       	       	      AND BIC  = NEW.BIC_benificiaire; 
	    
	     ---- SI QUELQUE CHOSE SE PASSE MAL, LA TRANSACTION EST IMMÉDIATEMENT ANNULÉE
	     EXCEPTION 
	     	       WHEN OTHERS THEN 
	     	       RAISE EXCEPTION 'ERREUR SERIEUSE :  La transaction a été annulée';
	     	       END;
	     

	     --- ON CALCULE LA FACTURATION DU VIREMENT	
	     
	     SELECT id_client INTO fac
	     FROM r_client_compte NATURAL JOIN t_compte 
	     WHERE num_compte = NEW.num_compte_creditaire;
	     
	     IF fac IN(SELECT id_client FROM r_client_compte NATURAL JOIN t_compte WHERE (IBAN = NEW.IBAN_benificiaire  AND BIC = NEW.BIC_benificiaire )) THEN
	     	facturation := 0;
	     END IF; 		     
	     
	      --- ON FACTURE LE VIREMENT
	     	 UPDATE t_compte SET solde = solde - facturation
      	     	 WHERE num_compte = NEW.num_compte_creditaire;
	     
	      --- ON VERIFIE SI ON DÉPASSE PAS LE DÉCOUVERT AUTORISÉ 
	      	  
		  SELECT id_client,solde,decouvert into s 
		  FROM t_compte NATURAL JOIN t_client NATURAL JOIN r_client_compte
		  WHERE num_compte = NEW.num_compte_creditaire;
	     	  	 
			 IF s.solde < 0 THEN
		  	    RAISE NOTICE 'ATTENTION vous êtes désormais débitaire ';
			 END IF;
	     	 
             -- SI ON DÉPASSE LE DÉCOUVERT AUTORISÉE ON DEVIENT INTERDIT BANCAIRE    		 	 	 
			 IF s.solde < -(s.decouvert) THEN
		  	    RAISE INFO 'Vous avez dépassé votre découvert autorisé qui est de : % €',s.decouvert;
			    PERFORM pg_sleep(1);
			    RAISE INFO 'VOUS ÊTES INTERDIT BANCAIRE';
			    PERFORM ajout_interdit(s.id_client,'DÉPASSEMENT DU DÉCOUVERT AUTORISÉE');
			 END IF;
	     
	     SELECT nom INTO nom_c FROM t_compte NATURAL JOIN t_client NATURAL JOIN r_client_compte 
	     WHERE  num_compte = NEW.num_compte_creditaire;
	     
	     
	     SELECT nom INTO nom_b FROM t_compte NATURAL JOIN t_client NATURAL JOIN r_client_compte 
	     WHERE  IBAN = NEW.IBAN_benificiaire  AND BIC = NEW.BIC_benificiaire;
	     
	     RAISE INFO 'Virement efféctué de  "%" vers "%" facturé à : % €',upper(nom_c.nom),upper(nom_b.nom),facturation; 
	     RAISE INFO 'NOUVEAU SOLDE = %€',s.solde;
	     
	     END IF; --type_virement ='U'	
	     
       RETURN NULL;
       END;
$tg_virement$ LANGUAGE 'plpgsql';


/************************************************************************************************************************************************************************/ 
/* 									FERMETURE D'UN COMPTE 										*/
/************************************************************************************************************************************************************************/

CREATE OR REPLACE FUNCTION f_fermeture_compte() RETURNS TRIGGER AS $tg_fermeture_compte$

       DECLARE
       ligne record;
       id record;
       is_m boolean;
       is_i boolean; 
       is_d boolean;
       
       BEGIN
       
	     ---- ON VERIFIE SI LE CLIENT N'ES PAS INTERDIT BANCAIRE && SI C'EST BIEN LE MANDATAIRE DU COMPTE
	      	  
		  is_m = is_mandataire (OLD.num_compte);
		  is_i = is_interdit (OLD.num_compte);
		  is_d = is_debitaire (OLD.num_compte);
		  
		  IF is_i = TRUE OR is_m = FALSE OR is_d= TRUE THEN
		     RAISE EXCEPTION 'FERMETURE DU COMPTE < % > IMPOSSIBLE',OLD.num_compte;
		  END IF;
	    	  	  
            DELETE FROM r_client_compte CASCADE WHERE num_compte = OLD.num_compte;
	    RAISE NOTICE 'LE COMPTE NUMERO < % > À BIEN ÉTÉ FERMÉ',OLD.num_compte;       

       RETURN OLD;
       END;

$tg_fermeture_compte$ LANGUAGE 'plpgsql';






/************************************************************************************************************************************************************************/
/*							 SUPPRIMER UN INTERDIT BANCAIRE					                                                */
/************************************************************************************************************************************************************************/

CREATE OR REPLACE FUNCTION f_del_interdit() RETURNS TRIGGER AS $tg_del_interdit$
       DECLARE 
       d record;
       BEGIN
       
			
		SELECT * INTO d FROM t_client NATURAL JOIN t_interdit_bancaire WHERE id_client = OLD.id_client;
		
	        IF d.date_regularisation > current_date THEN
		   RAISE EXCEPTION 'Mr/Mme "% %" NÉ(E) LE "%" N''A PAS ENCORE RÉGULARISÉ SA SITUATION',upper(d.nom),upper(d.prenom),d.date_naissance;
		END IF;
       RETURN NULL;
       END;	
$tg_del_interdit$ LANGUAGE 'plpgsql';



/************************************************************************************************************************************************************************/
/*								VIREMENTS PERMANANTS					                                               */
/************************************************************************************************************************************************************************/


CREATE OR REPLACE FUNCTION f_virement_perm() RETURNS TRIGGER AS $tg_virement_perm$

       DECLARE 
       v record;
       t_m INT;
       t_t INT;
       i INT;
       vp INT;
       vp1 INT;
       
       date_final DATE;
       BEGIN
       
       RAISE NOTICE 'Verification des virements permanants déclanché';
         
		 
	--- ON VERIFIE QU'APRÈS CHANGEMENT DE DATE "FICTIVE" IL Y'A OU PAS DES VIREMENT PERMANANT A EFFECTUER	 	 
	--SELECT * INTO v FROM r_virement,t_cal WHERE type_virement ='P';
	SELECT COUNT (*) INTO i FROM r_virement,t_cal WHERE type_virement ='P';
		
	IF i=0 THEN 
	RAISE EXCEPTION 'AUCUN VIREMENT PERMANANT À EFFECTUER';
	END IF;
	
	FOR v IN
	    SELECT * FROM r_virement,t_cal WHERE type_virement ='P'
	LOOP    

	--- VIREMENTS MONSUELS
	IF v.periode ='M' THEN
	   
	   IF v.date_virement= v.date_cal THEN
	      vp= virement_perm (v.num_compte_creditaire,v.IBAN_benificiaire,v.BIC_benificiaire,'U',v.montant_virement,'M',v.date_virement);
	      
	      date_final := (v.date_virement + interval '1 month')::date;
	  
			UPDATE r_virement SET date_virement = date_final 
	  		WHERE num_compte_creditaire = v.num_compte_creditaire 
			AND IBAN_benificiaire =v.IBAN_benificiaire 
			AND BIC_benificiaire =v.BIC_benificiaire 
			AND type_virement='P'
			AND periode = 'M';

	      RAISE INFO 'Virement Monsuel effectué!';   
	  END IF;
	END IF;

	----- VIREMENTS TRIMESTRIELS
	IF v.periode ='T' THEN
	      IF v.date_virement= v.date_cal THEN
	      	 vp= virement_perm (v.num_compte_creditaire,v.IBAN_benificiaire,v.BIC_benificiaire,'U',v.montant_virement,'T',v.date_virement);
	      	 date_final := (v.date_virement + interval '3 month')::date;
	  
			UPDATE r_virement SET date_virement = date_final 
	  		WHERE num_compte_creditaire = v.num_compte_creditaire 
			AND IBAN_benificiaire =v.IBAN_benificiaire 
			AND BIC_benificiaire =v.BIC_benificiaire 
			AND type_virement='P'
			AND periode = 'T';
	         RAISE INFO 'Virement Trimestriel effectué!';   
	     END IF;
	END IF;

	---- VIREMENTS SEMESTRIELS
	IF v.periode ='S' THEN
	      IF v.date_virement= v.date_cal THEN
	      	 vp= virement_perm (v.num_compte_creditaire,v.IBAN_benificiaire,v.BIC_benificiaire,'U',v.montant_virement,'S',v.date_virement);
	      	 date_final := (v.date_virement + interval '6 month')::date;
	  
			UPDATE r_virement SET date_virement = date_final 
	  		WHERE num_compte_creditaire = v.num_compte_creditaire 
			AND IBAN_benificiaire =v.IBAN_benificiaire 
			AND BIC_benificiaire =v.BIC_benificiaire 
			AND type_virement='P'
			AND periode = 'S';
	     RAISE INFO 'Virement Semestriel effectué!';   
	     END IF;  
	END IF;


	---- VIREMENTS ANNUELS
	IF v.periode ='A' THEN
	   IF v.date_virement= v.date_cal THEN
	      vp= virement_perm (v.num_compte_creditaire,v.IBAN_benificiaire,v.BIC_benificiaire,'U',v.montant_virement,'A',v.date_virement);
	      date_final := (v.date_virement + interval '1 year')::date;
	  
			UPDATE r_virement SET date_virement = date_final 
	  		WHERE num_compte_creditaire = v.num_compte_creditaire 
			AND IBAN_benificiaire =v.IBAN_benificiaire 
			AND BIC_benificiaire =v.BIC_benificiaire 
			AND type_virement='P'
			AND periode = 'A';
		
	     RAISE INFO 'Virement Annuel effectué!';   
	   END IF;
	END IF;
	
	END LOOP;
	
	
	RETURN NULL;
	END;

$tg_virement_perm$ LANGUAGE 'plpgsql';




/************************************************************************************************************************************************************************/
/*								RETRAIT/DÉPÔPT D'ESPÈCES						                               */
/************************************************************************************************************************************************************************/

CREATE OR REPLACE FUNCTION op (num NUMERIC,mont NUMERIC,type_op CHAR) RETURNS numeric AS $$

       DECLARE
       nv_solde NUMERIC;
       is_i boolean;
       is_d boolean;
       BEGIN
		-- ON VERIFIE SI LE CLIENT EST INTERDIT BANCAIRE
		is_i = is_interdit (num);
		IF is_i = TRUE THEN
		     RAISE EXCEPTION 'OPERATION IMPOSSIBLE';
		  END IF; 	

       
		IF type_op ='R' THEN
		   -- SI LE CLIENT EST DÉBITEUR IL POURRA PAS RETIRER 
		   is_d = is_debitaire (num);	     
		   	IF is_d = TRUE THEN
		     	RAISE EXCEPTION ' RETRAIT IMPOSSIBLE';	
		     	END IF;
		
		   UPDATE t_compte SET solde = solde - mont WHERE num_compte =num;
		   RAISE NOTICE 'RETRAIT EFFECTUÉ';
		END IF;

		IF type_op = 'D' THEN
		   UPDATE t_compte SET solde = solde + mont WHERE num_compte =num;
		   RAISE NOTICE 'DÉPÔT EFFECTUÉ';
		END IF;
		
		SELECT solde INTO nv_solde FROM t_compte WHERE num_compte = num;
		
		-- ARCHIVAGE DES OPERATIONS 
		INSERT INTO t_archive 
       	      	    VALUES (num,type_op,mont,nv_solde,current_timestamp);
		
	RETURN nv_solde;
	END;			       
$$ LANGUAGE 'plpgsql'; 


/************************************************************************************************************************************************************************/
/*							    M À J DU RELEVÉ BANCAIRE							                               */
/************************************************************************************************************************************************************************/

/*
CREATE OR REPLACE FUNCTION f_maj_releve () RETURNS TRIGGER AS $tg_maj_releve$

       DECLARE
       BEGIN
       
       ---- LA FONCTION MET A JOUR LA REQUETE POUR LE RELEVÉ BANCAIRE	
       	       		DROP VIEW v_releve1;
			CREATE VIEW v_releve1 AS SELECT * FROM r_virement;
			DROP VIEW v_releve2;
			CREATE VIEW v_releve2 AS SELECT * FROM t_archive;
 
       RETURN NULL;		  
       END;

$tg_maj_releve$ LANGUAGE 'plpgsql'; 



---------------- donne le relevé



CREATE OR REPLACE FUNCTION f_releve () RETURNS TRIGGER AS $tg_releve$

       DECLARE
       BEGIN
              IF date_cal = (date_cal + interval '1 moth')::date THEN
	      	RAISE INFO 'Relevé de compte effectué';
       	      END IF;
       RETURN NULL;		  
       END;

$tg_releve$ LANGUAGE 'plpgsql'; 
*/