DROP TABLE EAM_ACTIVOS;
CREATE TABLE EAM_ACTIVOS
(
  TIPO_RED       VARCHAR2(100),
  NOMBRE_RED     VARCHAR2(100),  
  CLASE          VARCHAR2(50),
  G3E_FID        NUMBER(10),
  G3E_FNO        NUMBER(10),
  CODIGO_ACTIVO  VARCHAR2(50),
  UBICACION      VARCHAR2(100),
  NIVEL          NUMBER,
  FID_PADRE      NUMBER,
  NIVEL_SUPERIOR VARCHAR2(100),
  DESCRIPCION    VARCHAR2(100),
  ACTIVO         NUMBER,
  ORDEM          NUMBER,
  FECHA_ACT      DATE
);


comment on column EAM_ACTIVOS.TIPO_RED
is 'Tipo de la RED (Matriz, Ramal u Circuito)';

comment on column EAM_ACTIVOS.NOMBRE_RED
is 'Nombre de la RED (circuito, ramal u linea primaria)';

comment on column EAM_ACTIVOS.CLASE
is 'Nombre de la clase del activo (nivel 6 u 7)';
  
comment on column EAM_ACTIVOS.G3E_FID
is 'G3E_FID del Activo';
  
comment on column EAM_ACTIVOS.G3E_FNO
is 'G3E_FNO del Activo';
  
comment on column EAM_ACTIVOS.CODIGO_ACTIVO
is 'Codigo del Activo que se genera para el EAM';
  
comment on column EAM_ACTIVOS.UBICACION
is 'Código de la Ubicación del Activo (Nivel 5)';

comment on column EAM_ACTIVOS.NIVEL
is 'Nivel actual del activo (6 u 7)';
  
comment on column EAM_ACTIVOS.FID_PADRE
is 'FID que tiene alguna relación para generar el activo actual.';
  
comment on column EAM_ACTIVOS.NIVEL_SUPERIOR
is 'CODIGO_ACTIVO del activo padre que tiene alguna relación para generar el activo actual';
  
comment on column EAM_ACTIVOS.ACTIVO
is 'Número de agrupación del activo para generar lineas (solo para TRAMOS)';
  
comment on column EAM_ACTIVOS.ORDEM
is 'Secuencia de la agrupación del activo para generar lineas (solo para TRAMOS)';

comment on column EAM_ACTIVOS.FECHA_ACT
is 'La ultima fecha que hube cambios en este activo';


comment on column EAM_ACTIVOS.DESCRIPCION
is 'Descripcion del activo';



DROP TABLE EAM_ACTIVOS_TEMP;
CREATE TABLE EAM_ACTIVOS_TEMP
(
  TIPO_RED       VARCHAR2(100),
  NOMBRE_RED     VARCHAR2(100), 
  CLASE          VARCHAR2(50),
  G3E_FID        NUMBER(10),
  G3E_FNO        NUMBER(10),
  CODIGO_ACTIVO  VARCHAR2(50),
  UBICACION      VARCHAR2(100),
  NIVEL          NUMBER,
  FID_PADRE      NUMBER,
  NIVEL_SUPERIOR VARCHAR2(100),
  DESCRIPCION    VARCHAR2(100),
  ACTIVO         NUMBER,
  ORDEM          NUMBER,
  FECHA_ACT      DATE
);

DROP TABLE EAM_ACTIVOS_RET;
CREATE TABLE EAM_ACTIVOS_RET
(
  TIPO_RED       VARCHAR2(100),
  NOMBRE_RED     VARCHAR2(100), 
  CLASE          VARCHAR2(50),
  G3E_FID        NUMBER(10),
  G3E_FNO        NUMBER(10),
  CODIGO_ACTIVO  VARCHAR2(50),
  UBICACION      VARCHAR2(100),
  NIVEL          NUMBER,
  FID_PADRE      NUMBER,
  NIVEL_SUPERIOR VARCHAR2(100),
  DESCRIPCION    VARCHAR2(100),
  ACTIVO         NUMBER,
  ORDEM          NUMBER,
  FECHA_ACT      DATE
);

DROP TABLE EAM_ACTIVOS_ALL;
CREATE TABLE EAM_ACTIVOS_ALLL
(
  TIPO_RED       VARCHAR2(100),
  NOMBRE_RED     VARCHAR2(100), 
  CLASE          VARCHAR2(50),
  G3E_FID        NUMBER(10),
  G3E_FNO        NUMBER(10),
  CODIGO_ACTIVO  VARCHAR2(50),
  UBICACION      VARCHAR2(100),
  NIVEL          NUMBER,
  FID_PADRE      NUMBER,
  NIVEL_SUPERIOR VARCHAR2(100),
  DESCRIPCION    VARCHAR2(100),
  ACTIVO         NUMBER,
  ORDEM          NUMBER,
  FECHA_ACT      DATE
);

DROP TABLE EAM_UBICACION;
CREATE TABLE EAM_UBICACION
(
  CLASE                      VARCHAR2(50),
  G3E_FID                    NUMBER(10),
  G3E_FNO                    NUMBER(5),
  CODIGO                     VARCHAR2(100),
  CODIGO_UBICACION           VARCHAR2(100),
  NIVEL                      NUMBER,
  NIVEL_SUPERIOR             VARCHAR2(50),
  DESCRIPCION                VARCHAR2(100),
  FECHA_ACT                  DATE
);

DROP TABLE EAM_UBICACION_TEMP;
CREATE TABLE EAM_UBICACION_TEMP
(
  CLASE                      VARCHAR2(50),
  G3E_FID                    NUMBER(10),
  G3E_FNO                    NUMBER(5),
  CODIGO                     VARCHAR2(100),
  CODIGO_UBICACION           VARCHAR2(100),
  NIVEL                      NUMBER,
  NIVEL_SUPERIOR             VARCHAR2(50),
  DESCRIPCION                VARCHAR2(100),
  FECHA_ACT                  DATE
);


comment on column EAM_UBICACION.CLASE
is 'Nombre de la clase del activo (nivel 5)';
  
comment on column EAM_UBICACION.G3E_FID
is 'G3E_FID del Padre de la Ubicacion';
  
comment on column EAM_UBICACION.G3E_FNO
is 'G3E_FNO del Padre de la Ubicacion';

comment on column EAM_UBICACION.CODIGO
is 'Codigo de la ubicación';
  
comment on column EAM_UBICACION.CODIGO_UBICACION
is 'Código de la Ubicación con formato';

comment on column EAM_UBICACION.NIVEL
is 'Nivel actual de la ubicación (nível 5)';
  
comment on column EAM_UBICACION.NIVEL_SUPERIOR
is 'Nombre de la ubicación superior';
  
comment on column EAM_UBICACION.FECHA_ACT
is 'La ultima fecha que hube cambios en esta ubicación';

comment on column EAM_UBICACION.DESCRIPCION  
is 'Descripción de la ubicación';
  

DROP TABLE EAM_ERRORS;
CREATE TABLE EAM_ERRORS
(
  CIRCUITO     VARCHAR2(50),
  G3E_FID      NUMBER(10),
  G3E_FNO      NUMBER(10),
  FECHA        DATE,
  DESCRIPCION  VARCHAR2(100)
);


DROP TABLE EAM_CONFIG;
CREATE TABLE EAM_CONFIG
(
  DESCRIPCION  VARCHAR2(50),
  VALOR        VARCHAR2(50)
);



insert into eam_config values ('TRAMO', 831242);
insert into eam_config values ('TRAMO', 823614);
insert into eam_config values ('TRAMO', 716056);
insert into eam_config values ('TRAMO', 498810);
insert into eam_config values ('TRAMO', 295863);
insert into eam_config values ('TRAMO', 193075);
insert into eam_config values('ClaseTramosMatriz','TRAMO');
insert into eam_config values('ClaseEstacionSeccionamiento','ESTACION VALVULA DE SECCIONAMIENTO');
insert into eam_config values('ClaseInstrumentacion','INSTRUMENTACION Y CONTROL');
insert into eam_config values('ClaseObraCivilSeccionamiento','OBRA CIVIL SECCIONAMIENTO');
insert into eam_config values('ClaseByPass','BY-PASS');
insert into eam_config values('ClaseObraCivilMatriz','OBRA CIVIL MATRIZ');
insert into eam_config values('ClaseRamal','RAMAL');
insert into eam_config values('ClaseCircuito','CIRCUITO');
insert into eam_config values('ClaseTuberiaRamal','TUBERIA PRIMARIA');
insert into eam_config values('ClaseObraCivilRamal','OBRA CIVIL RAMAL');
insert into eam_config values('ClaseArteria','ARTERIA');
insert into eam_config values('ClasePolivalvulaArteria','POLIVALVULA ARTERIA');
insert into eam_config values('ClaseTuberiaArteria','TUBERIA ARTERIA');
insert into eam_config values('ClaseObraCivilArteria','OBRA CIVIL ARTERIA');
insert into eam_config values('ClaseAnillo','ANILLO');
insert into eam_config values('ClasePolivalvulaAnillo','POLIVALVULA ANILLO');
insert into eam_config values('ClaseTuberiaAnillo','TUBERIA ANILLO');
insert into eam_config values('ClaseObraCivilAnillo','OBRA CIVIL ANILLO');
insert into eam_config values('LineaMatrizRedMetropolitana','LMV');
insert into eam_config values('RamalesRedMetropolitana','RMV');
insert into eam_config values('CeldasKirkRedMetropolitana','CKV');
insert into eam_config values('ProteccionCatodiaRedMetropolitana','PCV');
insert into eam_config values('SistemasValvulasRedMetropolitana','VAV');
insert into eam_config values('LineaSecundariaRedMetropolitana','LSVA');
insert into eam_config values('LineaMatrizRedRegionAntioquia','LMR');
insert into eam_config values('RamalesRedRegionAntioquia','RMR');
insert into eam_config values('CeldasKirkRedRegionAntioquia','CKR');
insert into eam_config values('ProteccionCatodiaRedRegionAntioquia','PCR');
insert into eam_config values('SistemasValvulasRedRegionAntioquia','VAR');
insert into eam_config values('LineaSecundariaRedRegionAntioquia','LSRA');
insert into eam_config values('RedMetropolitanaMunId', 'CALDAS');
insert into eam_config values('RedMetropolitanaMunId', 'LA ESTRELLA');
insert into eam_config values('RedMetropolitanaMunId', 'ITAGUI');
insert into eam_config values('RedMetropolitanaMunId', 'SABANETA');
insert into eam_config values('RedMetropolitanaMunId', 'ENVIGADO');
insert into eam_config values('RedMetropolitanaMunId', 'MEDELLIN');
insert into eam_config values('RedMetropolitanaMunId', 'BELLO');
insert into eam_config values('RedMetropolitanaMunId', 'COPACABANA');
insert into eam_config values('RedMetropolitanaMunId', 'GIRARDOTA');
insert into eam_config values('RedMetropolitanaMunId', 'BARBOSA');
insert into eam_config values('ClaseValvulaSeccionamiento', 'VALVULA DE SECCIONAMIENTO');
insert into eam_config values('ClaseUnidadRectificadora','UNIDAD RECTIFICADORA');
insert into eam_config values('ClaseRectificador','RECTIFICADOR');
insert into eam_config values('ClaseObraCivilRectificador','OBRA CIVIL RECTIFICADOR');
insert into eam_config values('ClasePedestalMonitoreo','PEDESTAL DE MONITOREO');
insert into eam_config values('ClaseUnidadAislamiento','UNIDAD DE AISLAMIENTO');
insert into eam_config values('ClaseCeldaKirk','CELDA KIRK');
insert into eam_config values('ClaseEstacionDerivacion','ESTACION DE VALVULAS DE DERIVACION');
insert into eam_config values('ClaseValvulaDerivacion','VALVULA DE DERIVACION');
insert into eam_config values('ClaseObraCivilDerivacion','OBRA CIVIL DERIVACION');
insert into eam_config values('RegionLineaPrimaria','LINEA PRIMARIA');
commit;


--tipos
create or replace type eam_trace_record as object
(
g3e_id NUMBER(10),
g3e_fid NUMBER(10),
g3e_fno NUMBER(5),
g3e_node1 NUMBER(10),
g3e_node2 NUMBER(10),
grupo number(10),
ordem number(10),
tipo varchar2(30)
);
/



create or replace type eam_trace_table as table of eam_trace_record;
/

