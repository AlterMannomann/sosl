CREATE OR REPLACE VIEW sosl_plan_view
AS
  SELECT spla.plan_name
       , spla.plan_active
       , spla.plan_accepted
       , scrt.script_name
       , sbat.batch_base_path
       , scrt.script_description
       , splg.order_nr AS group_order_nr
       , sgrp.order_nr AS script_order_nr
       , splg.plan_group_description
       , sgrp.batch_description
       , sbat.batch_group_description
       , spla.plan_id
       , splg.batch_group_id
       , sgrp.script_id
       , splg.group_plan_id
       , sgrp.batch_id
    FROM sosl_batch_plan spla
    LEFT OUTER JOIN sosl_group_plan splg
      ON spla.plan_id = splg.plan_id
    LEFT OUTER JOIN sosl_script_group sgrp
      ON splg.batch_group_id = sgrp.batch_group_id
    LEFT OUTER JOIN sosl_batch_group sbat
      ON splg.batch_group_id = sbat.batch_group_id
    LEFT OUTER JOIN sosl_script scrt
      ON sgrp.script_id = scrt.script_id
   ORDER BY spla.plan_id
          , splg.batch_group_id
          , splg.order_nr
          , sgrp.order_nr
;