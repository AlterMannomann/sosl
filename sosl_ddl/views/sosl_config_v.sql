-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
CREATE OR REPLACE VIEW sosl_config_v
AS
    WITH cfg AS
         (SELECT config_name
               , CASE
                   WHEN config_name != 'SOSL_PATH_CFG'
                   THEN config_value
                   ELSE CASE
                          WHEN sosl_util.has_role(SYS_CONTEXT('USERENV', 'CURRENT_USER'), 'SOSL_REVIEWER')
                          THEN config_value
                          ELSE '***'
                        END
                 END AS config_value
               , CASE
                   WHEN config_name = 'SOSL_SCHEMA'
                   THEN 'Schema setup'
                   WHEN config_name = 'SOSL_RUNMODE'
                   THEN 'Database and server'
                   WHEN config_name IN ( 'SOSL_MAX_PARALLEL'
                                       , 'SOSL_DEFAULT_WAIT'
                                       , 'SOSL_NOJOB_WAIT'
                                       , 'SOSL_PAUSE_WAIT'
                                       , 'SOSL_START_JOBS'
                                       , 'SOSL_STOP_JOBS'
                                       )
                   THEN 'Database configuration'
                   WHEN config_name IN ( 'SOSL_SERVER_STATE'
                                       , 'SOSL_PATH_CFG'
                                       , 'SOSL_PATH_TMP'
                                       , 'SOSL_PATH_LOG'
                                       , 'SOSL_START_LOG'
                                       , 'SOSL_BASE_LOG'
                                       , 'SOSL_EXT_LOG'
                                       , 'SOSL_EXT_TMP'
                                       , 'SOSL_EXT_LOCK'
                                       , 'SOSL_EXT_ERROR'
                                       )
                   THEN 'Server configuration'
                   ELSE 'Unknown parameter'
                 END                                                  AS configuration_by
               , config_type
               , CASE
                   WHEN config_max_length = -1
                    AND config_type       = 'CHAR'
                   THEN '4000 chars'
                   WHEN config_max_length = -1
                    AND config_type       = 'NUMBER'
                   THEN 'max int length'
                   ELSE TO_CHAR(config_max_length) || ' chars'
                 END                                                  AS length_limit
               , config_description
               , TO_CHAR(updated, 'YYYY-MM-DD HH24:MI:SS')            AS updated
               , updated_by
               , updated_by_os
               , TO_CHAR(created, 'YYYY-MM-DD HH24:MI:SS')            AS created
               , created_by
               , created_by_os
               , CASE
                   WHEN config_name = 'SOSL_SCHEMA'
                   THEN 7
                   WHEN config_name = 'SOSL_RUNMODE'
                   THEN 1
                   WHEN config_name IN ( 'SOSL_START_JOBS'
                                       , 'SOSL_STOP_JOBS'
                                       )
                   THEN 2
                   WHEN config_name = 'SOSL_MAX_PARALLEL'
                   THEN 3
                   WHEN config_name IN ( 'SOSL_DEFAULT_WAIT'
                                       , 'SOSL_NOJOB_WAIT'
                                       , 'SOSL_PAUSE_WAIT'
                                       )
                   THEN 4
                   WHEN config_name = 'SOSL_SERVER_STATE'
                   THEN 5
                   WHEN config_name IN ( 'SOSL_PATH_CFG'
                                       , 'SOSL_PATH_TMP'
                                       , 'SOSL_PATH_LOG'
                                       , 'SOSL_START_LOG'
                                       , 'SOSL_BASE_LOG'
                                       , 'SOSL_EXT_LOG'
                                       , 'SOSL_EXT_TMP'
                                       , 'SOSL_EXT_LOCK'
                                       , 'SOSL_EXT_ERROR'
                                       )
                   THEN 6
                   ELSE 8
                 END                                                  AS config_order
            FROM sosl_config
         )
  SELECT cfg.config_name
       , cfg.config_value
       , cfg.configuration_by
       , cfg.config_type
       , cfg.length_limit
       , cfg.config_description
       , cfg.updated
       , cfg.updated_by
       , cfg.updated_by_os
       , cfg.created
       , cfg.created_by
       , cfg.created_by_os
    FROM cfg
   ORDER BY cfg.config_order
          , cfg.config_name
;
GRANT SELECT ON sosl_config_v TO sosl_user;