
/*******************************  TRIGGERS ***********************************************/

----------------------------------- tg_ouverture_compte -----------------------------------
DROP TRIGGER IF EXISTS tg_ouverture_compte ON t_client;

CREATE TRIGGER tg_ouverture_compte
   AFTER INSERT	         
   ON t_client                      	 
   FOR EACH ROW                    	 
     EXECUTE PROCEDURE f_ouverture_compte();
-----------------------------------fin tg_ouverture_compte-------------------------------------



---------------------------------- tg_fermeture_compte -------------------------------------------
DROP TRIGGER IF EXISTS tg_fermeture_compte ON t_compte;

CREATE TRIGGER tg_fermeture_compte
   BEFORE  DELETE	         
   ON t_compte                     	 
   FOR EACH ROW                    	 
     EXECUTE PROCEDURE f_fermeture_compte();


-----------------------------------fin tg_fermeture_compte-------------------------------------


-----------------------------------tg_virement-------------------------------------------------
DROP TRIGGER IF EXISTS tg_virement ON r_virement;

CREATE TRIGGER tg_virement
    AFTER INSERT 
    ON r_virement
    FOR EACH ROW
      EXECUTE PROCEDURE f_virement();

-----------------------------------fin tg_virement---------------------------------------------

----------------------------------- tg_del_interdit -----------------------------------------------
DROP TRIGGER IF EXISTS tg_del_interdit ON t_interdit_bancaire;

CREATE TRIGGER tg_del_interdit
    BEFORE DELETE
    ON t_interdit_bancaire
    FOR EACH ROW
      EXECUTE PROCEDURE f_del_interdit();	




---------------------------------------------- tg_virement_perm ---------------------------------------------------------

DROP TRIGGER IF EXISTS tg_virement_perm ON t_cal;

CREATE TRIGGER tg_virement_perm
    AFTER UPDATE
    ON t_cal
    FOR EACH ROW
      EXECUTE PROCEDURE f_virement_perm();

------------------------------------------- fin tg_virement_perm-------------------------------------------------------------------------------


------------------------------------------------------------- tg_releve ---------------------------------------------------------------------------------
/*
DROP TRIGGER IF EXISTS tg_maj_releve ON t_compte;

CREATE TRIGGER tg_maj_releve
     AFTER UPDATE
     ON t_compte
     FOR EACH ROW 
       EXECUTE PROCEDURE f_maj_releve();
*/
---------------------------------------------------------- fin tg_releve-------------------------------------------------------------------------------



/** qui va donner le relevé chaque mois*/
/*
DROP TRIGGER IF EXISTS tg_releve ON t_cal;

CREATE TRIGGER tg_releve
     AFTER INSERT
     ON t_cal
     FOR EACH ROW 
       EXECUTE PROCEDURE f_releve();
*/