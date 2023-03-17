SET SERVEROUTPUT ON;

CREATE OR REPLACE PACKAGE traveler_admin_package AS
/* ex2. create a record type with appropiate components */
TYPE rec_user is RECORD (
        NAME USER_DEPENDENCIES.NAME%TYPE,
        TYPE USER_DEPENDENCIES.TYPE%TYPE,
        REFERENCED_NAME USER_DEPENDENCIES.REFERENCED_NAME%TYPE,
        REFERENCED_TYPE USER_DEPENDENCIES.REFERENCED_TYPE%TYPE
        );
-- create table        
TYPE user_table_type IS TABLE OF rec_user INDEX BY BINARY_INTEGER;
/* The procedure just to display disabled triggers */
PROCEDURE display_disabled_triggers;
/* The Function accepts the 'p_object_name' parameter so we can display neccesary informations */
FUNCTION all_dependent_objects(p_object_name IN USER_DEPENDENCIES.REFERENCED_NAME%TYPE) RETURN user_table_type;
 /*The procedure to display array from  all_dependent_objects*/
PROCEDURE print_dependent_objects(p_obj_array IN user_table_type);
END traveler_admin_package;
/
CREATE OR REPLACE PACKAGE BODY traveler_admin_package AS

PROCEDURE display_disabled_triggers IS
--Create cursor to get an pointor to informations that we want;
CURSOR trigger_cur IS SELECT trigger_name FROM user_triggers WHERE status = 'DISABLED';
--Create a flag to inform us about exception
l_flag NUMBER := 0;
BEGIN
    FOR i IN trigger_cur LOOP
    -- if flag == 1 the exception handle
    l_flag  := 1;
        DBMS_OUTPUT.PUT_LINE('Trigger: ' || i.trigger_name || ' is disabled');
    END LOOP;
    IF( l_flag = 0) THEN
    RAISE_APPLICATION_ERROR(-20201, 'No data found');    
    END IF;
END display_disabled_triggers;

FUNCTION all_dependent_objects(p_object_name IN USER_DEPENDENCIES.REFERENCED_NAME%TYPE) RETURN user_table_type AS
--Create cursor to get an pointor to informations that we want;
CURSOR obj_cur IS 
SELECT name, type, referenced_name, referenced_type
FROM user_dependencies WHERE referenced_name = UPPER(p_object_name);
-- LOCAL VARIABLE
l_object user_table_type;
iterator BINARY_INTEGER := 1;
--FLAG TO EXCEPTION
l_flag NUMBER := 0;
BEGIN
    -- FILL ARR LOOP
    FOR i IN obj_cur LOOP
        --EX
        l_flag := 1;
        l_object(iterator) := i;
        iterator := iterator + 1;
    END LOOP;
    IF( l_flag = 0) THEN
    RAISE_APPLICATION_ERROR(-20201, 'No data found for obj: '|| p_object_name );    
    END IF;
    RETURN l_object;
END all_dependent_objects;
PROCEDURE print_dependent_objects(p_obj_array IN user_table_type) AS
BEGIN
    FOR i IN p_obj_array.FIRST .. p_obj_array.LAST LOOP
            DBMS_OUTPUT.PUT_LINE(p_obj_array(i).name || '  ' || p_obj_array(i).type || '  ' || p_obj_array(i).REFERENCED_NAME ||
                            '  ' || p_obj_array(i).REFERENCED_TYPE);
    END LOOP;
END print_dependent_objects;


END traveler_admin_package;
/

-----TEST-----
SELECT trigger_name FROM user_triggers; -- NO ROWS
BEGIN 
-- works
traveler_admin_package.display_disabled_triggers;
END;
/
-- works
SELECT * FROM USER_DEPENDENCIES WHERE referenced_name = 'REGIONS';
DECLARE
l_obj traveler_admin_package.user_table_type;
BEGIN
l_obj := traveler_admin_package.all_dependent_objects('regions');
traveler_admin_package.print_dependent_objects(l_obj);
END;
BEGIN
-- not work :( EXCEPTION
l_obj := traveler_admin_package.all_dependent_objects('regioaa');
traveler_admin_package.print_dependent_objects(l_obj);
END;
/