

/****************************************************	JEUX DE TESTS	***********************************************************/

------------------------------------------ VIREMENTS UNIQUES --------------------------------------------------				

-- VIREMENT NORMAL :	 
INSERT INTO r_virement VALUES (11,'1412894063','AL0924316','PZSJDFJEUDK','U',70,default,default);


-- VIREMENT < 10 € :
   INSERT INTO r_virement VALUES (DEFAULT,'1412894063','AL0924316','PZSJDFJEUDK','U',7,default,default);


-- VIREMENT D'UN INTERDIT BANCAIRE :
INSERT INTO r_virement VALUES (DEFAULT,'1510522820','PO0119838','POLDKFJCHHH','U',80,default,default);


-- VIREMENT D'UN NON MANDATAIRE : '1731787529' 
INSERT INTO r_virement VALUES (DEFAULT,'1731787529','PO0119838','POLDKFJCHHH','U',90,default,default);


-- VIREMENT ENTRE LE MÊME CLIENT DE LA MÊME BANQUE 6153018636 
-- NOTE si on le fait plusieurs fois on voit que le client va devenir interdit bancaire
INSERT INTO r_virement VALUES (234,'6153018636','UZ9090902','AIJZZDKZDKZ','U',90,default,default);




------------------------------------------ VIREMENTS PERMANANTS --------------------------------------------------				

--VIREMENT MENSUEL :

INSERT INTO r_virement VALUES (DEFAULT,'1412894063','AL0924316','PZSJDFJEUDK','P',70,'M','2014-08-01');

INSERT INTO r_virement VALUES (DEFAULT,'7211722644','AL0924316','PZSJDFJEUDK','P',70,'M','2014-03-01');

INSERT INTO r_virement VALUES (DEFAULT,'1412894063','AL0924316','PZSJDFJEUDK','P',7,'S','2014-06-01');

INSERT INTO r_virement VALUES (DEFAULT,'7211722644','AL0924316','PZSJDFJEUDK','P',100,'S','2014-05-01');

INSERT INTO r_virement VALUES (DEFAULT,'7211722644','AL0924316','PZSJDFJEUDK','P',12,'T','2014-05-01');

INSERT INTO r_virement VALUES (DEFAULT,'1412894063','AL0924316','PZSJDFJEUDK','P',20,'A','2015-01-01');

INSERT INTO r_virement VALUES (DEFAULT,'6153018636','AL0924316','PZSJDFJEUDK','P',15,'A','2014-02-01');



------------------------------------------------------------- OUVERTURE D'UN COMPTE ---------------------------------------------------------------------------

-- OUVERTURE NORMALE
INSERT INTO t_client VALUES (209,'zineddine','zidane','algerie','1972-06-23');

-- INTERDIT BANCAIRE
INSERT INTO t_client VALUES (110,'Michael','Justina','algerie','1951-11-05');




------------------------------------------------ FERMETURE D'UN COMPTE -----------------------------------------------------------------------------------

-- FERMETURE D'UN COMPTE DÉBITEUR :
DELETE FROM t_compte CASCADE WHERE num_compte =1731787529;

-- FERMETURE D'UN INTEDRDIT BANCAIRE :
DELETE FROM t_compte CASCADE WHERE num_compte =1510522820;

-- FERMETURE NORMALE :
DELETE FROM t_compte CASCADE WHERE num_compte =1422527095;

--------------------------------------------------------------------------------------------------------------------------------------------------------------


---------------------------------------------- SUPPRESSION D'UN INTERDIT BANCAIRE PAS ENCORE EN RÉGLE ---------------------------------------------------------
DELETE FROM t_interdit_bancaire where id_client =4;

---------------------------------------------------------------------------------------------------------------------------------------------------------------


----------------------------------------------------------------- CONSULTER SOLDE -------------------------------------------------------------------------------------
SELECT consult_solde (1510522820);


----------------------------------------------------------------- OPERATIONS (RETRAIT/DEPOT)-------------------------------------------------------------------------------
--OPERATION SUR INTERDIT BANCAIRE
SELECT op (1510522820,90,'D');


--OPERATION SUR DEBITEUR
SELECT op(1731787529,80,'D');
SELECT op(1731787529,80,'R');


-- OPERATION NORMAL
SELECT op (1422527095,90,'D');






