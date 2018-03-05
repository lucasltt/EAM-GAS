--Rotero de Pruebas

--Ejecutar una taxonomia Limpia
begin
  delete from eam_activos;
  commit;
  delete from eam_ubicacion;
  commit;
  delete from eam_activos_ret;
  commit;
  eam_epm.eam_taxonomia;
end;
/


--Sin actualizar nada ejecutar la taxonomia de nuevo
begin
  eam_epm.eam_taxonomia;
end;
/

--Verificar si solo hay una fecha de actualizacion y se esta es la mas vieja
select distinct fecha_act from eam_activos;
select distinct fecha_act from eam_ubicacion;

--Simular una insercion de ubicacion y activos
delete from eam_ubicacion where g3e_fid = 2057531;
delete from eam_activos where g3e_fid  = 2057531;
commit;

--ejecutar la taxonomia de nuevo
begin
  eam_epm.eam_taxonomia;
end;
/

--Verificar la fecha y los regsitros 
select * from eam_ubicacion where g3e_fid = 2057531;
select * from eam_activos where g3e_fid  = 2057531;

--Simular un retiro
alter table b$ccomun disable all triggers;
update b$ccomun set estado = 'RETIRADO' where g3e_fid = 830807;
commit;
alter table b$ccomun enable all triggers;


--ejecutar la taxonomia de nuevo
begin
  eam_epm.eam_taxonomia;
end;
/

--Verificar la fecha y los regsitros 
select * from eam_activos_ret where g3e_fid = 830807;
select * from eam_activos where g3e_fid  = 830807;

--Regresar el dato
alter table b$ccomun disable all triggers;
update b$ccomun set estado = 'OPERACION' where g3e_fid = 830807;
commit;
alter table b$ccomun enable all triggers;



--Simular Elementos Retirados, elementos nuevos y elementos borrados
delete from eam_ubicacion where g3e_fid = 720781;
delete from eam_activos where g3e_fid  = 720781;
commit;

--Simular un retiro
alter table b$ccomun disable all triggers;
update b$ccomun set estado = 'RETIRADO' where g3e_fid = 2302214;
commit;
alter table b$ccomun enable all triggers;


--Simular una remocion
alter table b$ccomun disable all triggers;
update b$ccomun set g3e_fno = 1 where g3e_fid = 2302218;
commit;
alter table b$ccomun enable all triggers;

--ejecutar la taxonomia de nuevo
begin
  eam_epm.eam_taxonomia;
end;
/

--Regresar el dato
alter table b$ccomun disable all triggers;
update b$ccomun set estado = 'OPERACION' where g3e_fid = 2302214;
commit;
alter table b$ccomun enable all triggers;


alter table b$ccomun disable all triggers;
update b$ccomun set g3e_fno = 14100 where g3e_fid = 2302218;
commit;
alter table b$ccomun enable all triggers;

