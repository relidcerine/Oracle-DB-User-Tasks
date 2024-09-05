/*1. Log in with the user DBACOMPTOIRS.  */

connect DBACOMPTOIRS/psw
show user;
select username from user_users;

/*2. Create another user: ADMINCOMPTOIRS with the same tablespaces. */

create user Admin  identified by admin default tablespace intervention_tbs temporary tablespace intervention_temptbs;

connect system/psw

desc dba_users -- This view contains all users of the Oracle DBMS. 

select username, created from dba_users where username=upper('ADMINCOMPTOIRS');


/*3. Log in using this user. */

connect ADMINCOMPTOIRS /psw

-- Note: We notice that we cannot log in using this user because they do not have the necessary privileges (create session) to connect. 
-- Error: insufficient privileges.

/*4. Grant the create session privilege to this user and log in again. */

-- Grant the connect privilege to ADMIN from the DBACOMPTOIRS user

connect DBACOMPTOIRS/psw
grant create session to ADMINCOMPTOIRS;

-- Check in the Oracle catalog that the user has the privilege.

connect system/psw

desc dba_sys_privs

select privilege, admin_option from dba_sys_privs where grantee='ADMINCOMPTOIRS'; -- DBA_SYS_PRIVS contains all system privileges.

connect ADMINCOMPTOIRS /psw

select privilege, admin_option from user_sys_privs; -- USER_SYS_PRIVS contains all system privileges of the connected user.


/*5. Grant the following privileges to ADMINCOMPTOIRS: create tables, views, and users.*/

connect DBACOMPTOIRS/psw

grant create table, create view, create user to ADMINCOMPTOIRS ;

--verification

connect system/pswd

 select privilege, admin_option from dba_sys_privs where grantee='ADMINCOMPTOIRS';

connect ADMINCOMPTOIRS /psw

select privilege, admin_option from user_sys_privs;

-- Creating a table

create table test (a integer, b char(1));

-- no quota on the COMPTOIRS_TBS tablespace, so a quota needs to be granted

connect DBACOMPTOIRS/psw

alter user ADMINCOMPTOIRS  quota unlimited on COMPTOIRS_TBS;

connect ADMINCOMPTOIRS /psw

create table test (a integer, b char(1));

-- Verification in the catalog

select table_name from tabs;

insert into test values (1, 'b');
 
select * from test; -- The user is the owner of the table

-- Verification in the catalog

select object_name, object_type from user_objects;-- Find the objects of the connected user

-- creating a view

create view view1 as select a from test;

--Verification
select * from view1;

select object_name, object_type from user_objects;

connect system/pswd;

desc dba_objects;

select owner, object_name, object_type from dba_objects where owner='ADMINCOMPTOIRS';


-- Creating a user

Connect ADMINCOMPTOIRS/psw

create user usertest identified by psw;

-- Verification in the catalog

connect system/psw
select username, default_tablespace, temporary_tablespace, password, profile from dba_users where username =upper('usertest');


/*6. Execute the following query: SELECT * FROM PRODUIT; What do you notice? */

connect ADMINCOMPTOIRS /psw

Select * from  PRODUIT;

-- Result: ORA-00942: Table or view does not exist */


/*7. Grant read access to this user for the PRODUIT table. Execute the query Q1 now.*/

-- Grant the SELECT privilege on the PRODUIT table
connect DBACOMPTOIRS/psw

grant select on PRODUIT to ADMINCOMPTOIRS ;

-- Verify the privilege grant from the catalog by accessing the DBA_TAB_PRIVS view, which contains all object privileges.

connect system/psw

desc dba_tab_privs

select grantee, owner, table_name, privilege, grantable from dba_tab_privs where grantee='ADMINCOMPTOIRS';

connect ADMINCOMPTOIRS /psw

select * from user_tab_privs; 

Select * from  PRODUIT;

-- Result: ORA-00942: Table or view does not exist

-- You need to include the schema name of the table owner, DBACOMPTOIRS.

Select * from  DBACOMPTOIRS.PRODUIT;


/*8. We want to delete all products that are no longer sold. */

delete from DBACOMPTOIRS.produit where REFPROD not in (select REFPROD from DBACOMPTOIRS.detailcommande);

--ORA-00942: Table or view does not exist / on the table detailcommande

connect DBACOMPTOIRS/psw

grant select on detailcommande to ADMINCOMPTOIRS ;

connect ADMINCOMPTOIRS /psw

delete from DBACOMPTOIRS.produit where REFPROD not in (select REFPROD from DBACOMPTOIRS.detailcommande);

--ORA-01031: insufficient privileges


/*9. Grant delete rights to this user for the PRODUIT table and retry the deletion. */

connect DBACOMPTOIRS/psw

grant delete on PRODUIT to ADMINCOMPTOIRS ;

-- Verification

connect system/psw

 select grantee, owner, table_name, privilege, grantable from dba_tab_privs where grantee='ADMINCOMPTOIRS';

-- Execution from ADMINCOMPTOIRS

connect ADMINCOMPTOIRS /psw

select * from user_tab_privs;


delete from DBACOMPTOIRS.produit where REFPROD not in (select REFPROD from DBACOMPTOIRS.detailcommande);


/*10. Create an index NP_IX on the NOMPROD attribute of the PRODUIT table.*/

connect ADMINCOMPTOIRS /psw

create index NP_IX   on DBACOMPTOIRS.PRODUIT(nomprod);

-- Result: No privilege

/*11 Grant index creation rights to ADMINCOMPTOIRS for the PRODUIT table*/

connect DBACOMPTOIRS/psw

grant index on PRODUIT to ADMINCOMPTOIRS ;

-- Verification

connect system/psw

select grantee, owner, table_name, privilege, grantable from dba_tab_privs where grantee='ADMINCOMPTOIRS';

connect ADMINCOMPTOIRS /psw

Select * from user_tab_privs;

create index NP_IX   on DBACOMPTOIRS.PRODUIT(nomprod);

-- Result: Index created.

select object_name, object_type from user_objects;


/*12. Revoke the previously granted privileges.*/


-- First, revoke system privileges (you cannot revoke system and object privileges in the same query)
 
revoke all privileges from ADMINCOMPTOIRS;  (does not work because not all privileges were granted to ADMINCOMPTOIRS; it would work, for example, on DBACOMPTOIRS)

-- System privileges

connect DBACOMPTOIRS/psw

revoke create session, create user, create table, create view from ADMINCOMPTOIRS;

-- Verification

connect system/psw

select privilege , admin_option from dba_sys_privs where grantee=upper('ADMINCOMPTOIRS');

connect DBACOMPTOIRS/psw

-- Object privileges

revoke select, delete, index on produit from ADMINCOMPTOIRS;

revoke select on detailcommande from ADMINCOMPTOIRS;


/*13. Verify that the privileges have been removed.*/

-- Verification

connect system/psw

select privilege, admin_option from dba_sys_privs where grantee=upper('ADMINCOMPTOIRS');

select grantee,owner, grantor, table_name, privilege from dba_tab_privs where grantee=upper('ADMINCOMPTOIRS');


/*14.Create a profile "Comptoirs_Profil" characterized by: (3 simultaneous sessions allowed, 
No system call can consume more than 20 seconds of CPU, Each session cannot exceed 60 minutes, 
A system call cannot read more than 1200 blocks of data in memory and on disk, Each session cannot allocate more than 40 KB of memory in SGA, 
For each session, a maximum of 15 minutes of inactivity is allowed,  5 login attempts before account lockout, 
The password is valid for 70 days and must wait 50 days before it can be reused,  1 day of access restriction after 5 login attempts, 
The grace period that extends the use of the password before its change is 5 days)*/


connect DBACOMPTOIRS/psw

create profile Comptoirs_Profil limit
sessions_per_user 3
cpu_per_call 2000
connect_time 60
logical_reads_per_session 1200
private_sga 40K
idle_time 15
failed_login_attempts 5
password_lock_time 1
password_life_time 70
password_reuse_time 50
password_reuse_max unlimited
password_grace_time 5;


-- Verification

connect system/psw

select * from dba_profiles where profile=upper('Comptoirs_Profil');

select * from dba_profiles where profile=upper('Comptoirs_Profil') and limit <>'DEFAULT';

Desc dba_users;

select username, profile from dba_users where username=upper('ADMINCOMPTOIRS');

select username, profile from dba_users where username='DBACOMPTOIRS';


/*15. Assign this profile to the ADMINCOMPTOIRS user. Verify.*/

connect DBACOMPTOIRS/psw

alter user ADMINCOMPTOIRS  profile Comptoirs_Profil;

-- Verification

connect system/psw

select username, profile from dba_users where username=upper('ADMINCOMPTOIRS'); 


/*16. Create the role "GESTIONNAIRE_DE_COMPTOIRS" which can view the tables FOURNISSEUR, CLIENT, EMPLOYE, CATEGORIE, MESSAGER 
and can modify the tables PRODUIT, COMMANDE, and DETAILCOMMANDE.*/

connect DBACOMPTOIRS/psw

create role GESTIONNAIRE_DE_COMPTOIRS;

connect system/psw

select role from dba_roles where role='GESTIONNAIRE_DE_COMPTOIRS';

connect DBACOMPTOIRS/psw

grant select on FOURNISSEUR to GESTIONNAIRE_DE_COMPTOIRS;
grant select on CLIENT to GESTIONNAIRE_DE_COMPTOIRS;
grant select on EMPLOYE to GESTIONNAIRE_DE_COMPTOIRS;
grant select on CATEGORIE to GESTIONNAIRE_DE_COMPTOIRS;
grant select on MESSAGER to GESTIONNAIRE_DE_COMPTOIRS;
grant update on PRODUIT to GESTIONNAIRE_DE_COMPTOIRS;
grant update on ENTRAINER to GESTIONNAIRE_DE_COMPTOIRS;
grant update on COMMANDE to GESTIONNAIRE_DE_COMPTOIRS;
grant update on DETAILCOMMANDE to GESTIONNAIRE_DE_COMPTOIRS;

--- Verification

select USERNAME, GRANTED_ROLE from user_role_privs;

Comme c’est des privilèges objet qu’on a mis dans ce rôle, on consulte user_tab_pris: 

select privilege, table_name from user_tab_privs where grantee='GESTIONNAIRE_DES_GYMNASES';


/*17. Assign this role to ADMINCOMPTOIRS. Verify that the privileges assigned to the GESTIONNAIRE_DE_COMPTOIRS role have been transferred to the ADMINCOMPTOIRS user. */

connect DBACOMPTOIRS/psw

grant GESTIONNAIRE_DE_COMPTOIRS to ADMINCOMPTOIRS;

-- Verification

connect system/psw

select GRANTEE, GRANTED_ROLE from dba_role_privs where GRANTEE ='ADMINCOMPTOIRS ';

On ne peut plus vérifier sur user_role_privs pour ADMINCOMPTOIRS car on lui a enlevé le privilège de connexion (revoke create session), on ne peut plus se connecter avec.


*************************************************************************************************************************
-----Connect as DBACOMPTOIRS and try to drop ADMINCOMPTOIRS without adding CASCADE
connect DBACOMPTOIRS /psw
drop user ADMINCOMPTOIRS;

--It does not work; you are told to add CASCADE to the query because ADMINCOMPTOIRS created objects that need to be removed as well.
