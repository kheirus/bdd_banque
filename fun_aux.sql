------------------------------------------- DONNE UN STRING ALÉATOIREMENT AVEC NUMÉRO (pour le IBAN) ------------------------------------------------------------
CREATE OR REPLACE FUNCTION rstr(int)
RETURNS text AS $$
SELECT array_to_string(ARRAY(SELECT substring('ABCDEFGHIJKLMNOPQRSTUVWXYZ123456789' FROM (random()*21)::int + 1 FOR 1) 
                                FROM generate_series(1,$1)),
                       '') 
$$ LANGUAGE sql;
-------------------------------------------------------------------------------------------------------------------------------

-------------------------------------- DONNE UN STRING ALÉATOIREMENT SANS NUMÉRO NUMERO (pour le BIC)---------------------------
CREATE OR REPLACE FUNCTION rstr2(int)
RETURNS text AS $$
SELECT array_to_string(ARRAY(SELECT substring('ABCDEFGHIJKLMNOPQRSTUVWXYZ' FROM (random()*21)::int + 1 FOR 1) 
                                FROM generate_series(1,$1)),
                       '') 
$$ LANGUAGE sql;
--------------------------------------------------------------------------------------------------------------------------------



------------------------------------------- TESTE SI LE CLIENT (numéro de compte) EST OUI/NON MANDATAIRE --------------------------------

CREATE OR REPLACE FUNCTION is_mandataire(nc NUMERIC) RETURNS BOOLEAN AS $$
       
       DECLARE
       ligne record;
       BEGIN
	
		FOR ligne IN 
	     	      SELECT nom,prenom,id_client,num_compte,mandataire FROM t_client NATURAL JOIN r_client_compte NATURAL JOIN t_compte  WHERE id_client !=mandataire  
	    	       LOOP 
	               	  IF nc=ligne.num_compte THEN
			     RAISE NOTICE 'Mr/Mme "% %" n''est pas mandataire du compte numero : %',upper(ligne.prenom),upper(ligne.nom),ligne.num_compte;
	               	     RETURN FALSE;
			  END IF;
		       END LOOP;
       
       RETURN TRUE;
       END;
$$ LANGUAGE 'plpgsql';


-----------------------------------------------------------------------------------------------------------------------------------------------------------


-----------------------------------------TESTE SI LE CLIENT (numéro de nompte) EST OUI/NON INTERDIT BANCAIRE-----------------------------------------------

CREATE OR REPLACE FUNCTION is_interdit(nc NUMERIC) RETURNS BOOLEAN AS $$

       DECLARE 
       id record;
       BEGIN
       
		FOR id IN
	     	      SELECT * FROM t_client NATURAL JOIN r_client_compte NATURAL JOIN t_interdit_bancaire 
		      WHERE (date_regularisation > current_date OR date_regularisation IS NULL)
	     	      	    LOOP
		      	        IF nc = id.num_compte THEN
 	    	      		   RAISE NOTICE 'Mr/Mme : "% %" est interdit(e) bancaire depuis "%" pour le motif suivant : "%"',upper(id.prenom),upper(id.nom),id.date_interdit,upper(id.motif);             
		      		   RETURN TRUE;
		      		END IF;	 
	                    END LOOP;	   	

	RETURN FALSE;
	END;	      
$$ LANGUAGE 'plpgsql';

-------------------------------------- VERIFIE SI UN COMPTE EST OUI/NON DÉBITAIRE -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION is_debitaire(nc NUMERIC) RETURNS BOOLEAN AS $$
       
       DECLARE
       s NUMERIC;
       BEGIN
		SELECT solde INTO s FROM t_compte WHERE num_compte = nc;
		
		IF s <0 THEN
		   RAISE NOTICE 'CE COMPTE EST DÉBITAIRE';
		   RETURN TRUE;
		END IF;   	   
      RETURN FALSE;		
      END; 
$$ LANGUAGE 'plpgsql';

-------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------ AJOUTER UN CLIENT DANS LES INTERDITS BANCAIRE ---------------------------------------------------------------

CREATE OR REPLACE FUNCTION ajout_interdit(id_client INT, motif VARCHAR) RETURNS void AS $$
    
       DECLARE 
       date_regularisation DATE;
       BEGIN 

       date_regularisation = current_date + interval '5 year';
       INSERT INTO t_interdit_bancaire
       	      VALUES
	      (current_user,id_client,motif,current_date,date_regularisation);
       
       
       END;

$$ LANGUAGE 'plpgsql';



--------------------------------------------------------- INSERTION VIREMENT PERMANANT -------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION virement_perm (num NUMERIC, IBAN VARCHAR, BIC VARCHAR,t CHAR, montant NUMERIC, p CHAR, date_vir DATE) RETURNS INT AS $$
       
       DECLARE 
       id int;
       BEGIN
       
       ---- CALCULE DE DATE DE VIREMENT

       INSERT INTO r_virement VALUES (DEFAULT,num,iban,bic,t,montant,p,date_vir);
    SELECT id_virement INTO id FROM r_virement WHERE num_compte_creditaire=num AND iban_benificiaire = IBAN AND bic_benificiaire = bic;
    
       RETURN id;	
       END;
$$ LANGUAGE 'plpgsql'; 


-------------------------------------------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------- RELEVE DE COMPTE ----------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION releve_de_compte (num NUMERIC) RETURNS setof text AS $$

       DECLARE 
       v record;
       c record;
       BEGIN
			FOR v IN
       	    		      SELECT * FROM v_releve1 WHERE num_compte_creditaire = num
       	 		      LOOP
       	    		      RETURN next v;
       	    		      END LOOP;
			      
			FOR c IN
       	    		      SELECT * FROM v_releve2 WHERE num_compte = num
       	 		      LOOP
       	    		      RETURN next c;
       	    		      END LOOP;
      END;
$$ LANGUAGE 'plpgsql'; 

-------------------------------------------------------------------------------------------------------------------------------------------------------------