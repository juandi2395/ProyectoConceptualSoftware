/* iMedical - Base de Datos - Sistema SaaS Multitenant */

/* Base de Datos */

IF DB_ID(N'iMedical') IS NULL
BEGIN
    CREATE DATABASE iMedical
END
GO

USE iMedical
GO

/* Schemas */

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'tenant')
    EXEC('CREATE SCHEMA tenant')
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'security')
    EXEC('CREATE SCHEMA security')
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'billing')
    EXEC('CREATE SCHEMA billing')
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'clinical')
    EXEC('CREATE SCHEMA clinical')
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'inventory')
    EXEC('CREATE SCHEMA inventory')
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'audit')
    EXEC('CREATE SCHEMA audit')
GO

/* Tenant */

CREATE TABLE tenant.PlanServicio (
    PlanServicioID  INT IDENTITY(1,1) PRIMARY KEY,
    Nombre          NVARCHAR(100) NOT NULL,
    Descripcion     NVARCHAR(255) NULL,
    LimiteUsuarios  INT NOT NULL,
    PrecioMensual   DECIMAL(10,2) NOT NULL
)
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Catálogo de planes de suscripción SaaS que iData S.A. ofrece a las clínicas.',
    @level0type = N'SCHEMA',
    @level0name = N'tenant',
    @level1type = N'TABLE',
    @level1name = N'PlanServicio'
GO

CREATE TABLE tenant.Clinica (
    ClinicaID       INT IDENTITY(1,1) PRIMARY KEY,
    Nombre          NVARCHAR(150) NOT NULL,
    Identificacion  NVARCHAR(50) NOT NULL,
    Direccion       NVARCHAR(255) NULL,
    Telefono        NVARCHAR(30) NULL,
    Correo          NVARCHAR(150) NULL,
    PlanServicioID  INT NOT NULL,
    Estado          TINYINT NOT NULL DEFAULT 1,
    FechaAlta       DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_Clinica_Plan
        FOREIGN KEY (PlanServicioID)
        REFERENCES tenant.PlanServicio(PlanServicioID),

    CONSTRAINT CK_Clinica_Estado
        CHECK (Estado IN (1,2,3))
)
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Tenant (clínica) que utiliza la plataforma iMedical. Cada fila representa una clínica aislada lógicamente del resto.',
    @level0type = N'SCHEMA',
    @level0name = N'tenant',
    @level1type = N'TABLE',
    @level1name = N'Clinica'
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Estado del tenant: 1=Activo, 2=Suspendido, 3=Baja.',
    @level0type = N'SCHEMA',
    @level0name = N'tenant',
    @level1type = N'TABLE',
    @level1name = N'Clinica',
    @level2type = N'COLUMN',
    @level2name = N'Estado'
GO

/* Billing */

CREATE TABLE billing.Factura (
    FacturaID           INT IDENTITY(1,1) PRIMARY KEY,
    ClinicaID           INT NOT NULL,
    Periodo             CHAR(7) NOT NULL,
    MontoTotal          DECIMAL(10,2) NOT NULL,
    FechaEmision        DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    FechaVencimiento    DATE NOT NULL,
    EstadoPago          TINYINT NOT NULL DEFAULT 1,

    CONSTRAINT FK_Factura_Clinica
        FOREIGN KEY (ClinicaID)
        REFERENCES tenant.Clinica(ClinicaID),

    CONSTRAINT CK_Factura_EstadoPago
        CHECK (EstadoPago IN (1,2,3,4))
)
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Facturación periódica del servicio SaaS por clínica.',
    @level0type = N'SCHEMA',
    @level0name = N'billing',
    @level1type = N'TABLE',
    @level1name = N'Factura'
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Estado del pago: 1=Pendiente, 2=Pagada, 3=Vencida, 4=Anulada.',
    @level0type = N'SCHEMA',
    @level0name = N'billing',
    @level1type = N'TABLE',
    @level1name = N'Factura',
    @level2type = N'COLUMN',
    @level2name = N'EstadoPago'
GO

/* Security */

CREATE TABLE security.Rol (
    RolID       INT IDENTITY(1,1) PRIMARY KEY,
    Nombre      NVARCHAR(50) NOT NULL UNIQUE,
    Descripcion NVARCHAR(200) NULL
)
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Catálogo de roles del sistema.',
    @level0type = N'SCHEMA',
    @level0name = N'security',
    @level1type = N'TABLE',
    @level1name = N'Rol'
GO

INSERT INTO security.Rol (Nombre, Descripcion)
VALUES
    (N'AdministradorIData', N'Personal de iData S.A. que administra la plataforma y los tenants'),
    (N'Jefatura', N'Dueño(a) o responsable de la clínica'),
    (N'Medico', N'Profesional de la salud que atiende consultas'),
    (N'Asistente', N'Personal de enfermería que apoya la atención'),
    (N'Recepcionista', N'Gestiona pacientes y citas'),
    (N'Proveedor', N'Suministra insumos y medicamentos'),
    (N'Paciente', N'Usuario de la aplicación móvil con acceso de solo lectura')
GO

CREATE TABLE security.Usuario (
    UsuarioID       INT IDENTITY(1,1) PRIMARY KEY,
    ClinicaID       INT NULL,
    RolID           INT NOT NULL,
    Nombre          NVARCHAR(150) NOT NULL,
    Correo          NVARCHAR(150) NOT NULL,
    PasswordHash    VARBINARY(256) NOT NULL,
    MFAHabilitado   BIT NOT NULL DEFAULT 0,
    Estado          TINYINT NOT NULL DEFAULT 1,
    FechaCreacion   DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_Usuario_Clinica
        FOREIGN KEY (ClinicaID)
        REFERENCES tenant.Clinica(ClinicaID),

    CONSTRAINT FK_Usuario_Rol
        FOREIGN KEY (RolID)
        REFERENCES security.Rol(RolID),

    CONSTRAINT CK_Usuario_Estado
        CHECK (Estado IN (1,2,3))
)
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Cuentas de acceso al sistema. PasswordHash almacena el resultado de un algoritmo de hash seguro.',
    @level0type = N'SCHEMA',
    @level0name = N'security',
    @level1type = N'TABLE',
    @level1name = N'Usuario'
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Estado de la cuenta: 1=Activo, 2=Inactivo, 3=Bloqueado.',
    @level0type = N'SCHEMA',
    @level0name = N'security',
    @level1type = N'TABLE',
    @level1name = N'Usuario',
    @level2type = N'COLUMN',
    @level2name = N'Estado'
GO

/* Clinical */

CREATE TABLE clinical.Paciente (
    PacienteID      INT IDENTITY(1,1) PRIMARY KEY,
    ClinicaID       INT NOT NULL,
    Nombre          NVARCHAR(100) NOT NULL,
    Apellidos       NVARCHAR(100) NOT NULL,
    Identificacion  NVARCHAR(50) NOT NULL,
    FechaNacimiento DATE NOT NULL,
    Genero          TINYINT NOT NULL,
    TipoSangre      TINYINT NULL,
    Telefono        NVARCHAR(30) NULL,
    Correo          NVARCHAR(150) NULL,
    Direccion       NVARCHAR(255) NULL,
    Estado          TINYINT NOT NULL DEFAULT 1,
    FechaRegistro   DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_Paciente_Clinica
        FOREIGN KEY (ClinicaID)
        REFERENCES tenant.Clinica(ClinicaID),

    CONSTRAINT CK_Paciente_Genero
        CHECK (Genero IN (1,2,3)),

    CONSTRAINT CK_Paciente_TipoSangre
        CHECK (TipoSangre IS NULL OR TipoSangre BETWEEN 1 AND 8),

    CONSTRAINT CK_Paciente_Estado
        CHECK (Estado IN (1,2))
)
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Pacientes registrados en la clínica. Entidad central del dominio clínico.',
    @level0type = N'SCHEMA',
    @level0name = N'clinical',
    @level1type = N'TABLE',
    @level1name = N'Paciente'
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Género: 1=Masculino, 2=Femenino, 3=Otro.',
    @level0type = N'SCHEMA',
    @level0name = N'clinical',
    @level1type = N'TABLE',
    @level1name = N'Paciente',
    @level2type = N'COLUMN',
    @level2name = N'Genero'
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Tipo de sangre: 1=O+, 2=O-, 3=A+, 4=A-, 5=B+, 6=B-, 7=AB+, 8=AB-.',
    @level0type = N'SCHEMA',
    @level0name = N'clinical',
    @level1type = N'TABLE',
    @level1name = N'Paciente',
    @level2type = N'COLUMN',
    @level2name = N'TipoSangre'
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Estado del registro: 1=Activo, 2=Inactivo.',
    @level0type = N'SCHEMA',
    @level0name = N'clinical',
    @level1type = N'TABLE',
    @level1name = N'Paciente',
    @level2type = N'COLUMN',
    @level2name = N'Estado'
GO

CREATE TABLE clinical.Especialidad (
    EspecialidadID  INT IDENTITY(1,1) PRIMARY KEY,
    Nombre          NVARCHAR(100) NOT NULL UNIQUE
)
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Catálogo de especialidades médicas.',
    @level0type = N'SCHEMA',
    @level0name = N'clinical',
    @level1type = N'TABLE',
    @level1name = N'Especialidad'
GO

CREATE TABLE clinical.Medico (
    MedicoID        INT IDENTITY(1,1) PRIMARY KEY,
    UsuarioID       INT NOT NULL UNIQUE,
    ClinicaID       INT NOT NULL,
    EspecialidadID  INT NOT NULL,
    NumeroColegiado NVARCHAR(30) NOT NULL,

    CONSTRAINT FK_Medico_Usuario
        FOREIGN KEY (UsuarioID)
        REFERENCES security.Usuario(UsuarioID),

    CONSTRAINT FK_Medico_Clinica
        FOREIGN KEY (ClinicaID)
        REFERENCES tenant.Clinica(ClinicaID),

    CONSTRAINT FK_Medico_Especialidad
        FOREIGN KEY (EspecialidadID)
        REFERENCES clinical.Especialidad(EspecialidadID)
)
GO

CREATE TABLE clinical.CitaMedica (
    CitaID          INT IDENTITY(1,1) PRIMARY KEY,
    ClinicaID       INT NOT NULL,
    PacienteID      INT NOT NULL,
    MedicoID        INT NOT NULL,
    FechaHora       DATETIME2 NOT NULL,
    Motivo          NVARCHAR(255) NULL,
    Estado          TINYINT NOT NULL DEFAULT 1,
    FechaCreacion   DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_Cita_Clinica
        FOREIGN KEY (ClinicaID)
        REFERENCES tenant.Clinica(ClinicaID),

    CONSTRAINT FK_Cita_Paciente
        FOREIGN KEY (PacienteID)
        REFERENCES clinical.Paciente(PacienteID),

    CONSTRAINT FK_Cita_Medico
        FOREIGN KEY (MedicoID)
        REFERENCES clinical.Medico(MedicoID),

    CONSTRAINT CK_Cita_Estado
        CHECK (Estado IN (1,2,3,4,5))
)
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Citas médicas programadas.',
    @level0type = N'SCHEMA',
    @level0name = N'clinical',
    @level1type = N'TABLE',
    @level1name = N'CitaMedica'
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Estado de la cita: 1=Programada, 2=Confirmada, 3=Cancelada, 4=Completada, 5=No Asistió.',
    @level0type = N'SCHEMA',
    @level0name = N'clinical',
    @level1type = N'TABLE',
    @level1name = N'CitaMedica',
    @level2type = N'COLUMN',
    @level2name = N'Estado'
GO

CREATE TABLE clinical.ExpedienteClinico (
    ExpedienteID    INT IDENTITY(1,1) PRIMARY KEY,
    PacienteID      INT NOT NULL UNIQUE,
    ClinicaID       INT NOT NULL,
    Antecedentes    NVARCHAR(MAX) NULL,
    FechaCreacion   DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_Expediente_Paciente
        FOREIGN KEY (PacienteID)
        REFERENCES clinical.Paciente(PacienteID),

    CONSTRAINT FK_Expediente_Clinica
        FOREIGN KEY (ClinicaID)
        REFERENCES tenant.Clinica(ClinicaID)
)
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Expediente clínico único por paciente.',
    @level0type = N'SCHEMA',
    @level0name = N'clinical',
    @level1type = N'TABLE',
    @level1name = N'ExpedienteClinico'
GO

CREATE TABLE clinical.Consulta (
    ConsultaID      INT IDENTITY(1,1) PRIMARY KEY,
    ExpedienteID    INT NOT NULL,
    CitaID          INT NULL,
    MedicoID        INT NOT NULL,
    FechaHora       DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    MotivoConsulta  NVARCHAR(255) NULL,
    Observaciones   NVARCHAR(MAX) NULL,

    CONSTRAINT FK_Consulta_Expediente
        FOREIGN KEY (ExpedienteID)
        REFERENCES clinical.ExpedienteClinico(ExpedienteID),

    CONSTRAINT FK_Consulta_Cita
        FOREIGN KEY (CitaID)
        REFERENCES clinical.CitaMedica(CitaID),

    CONSTRAINT FK_Consulta_Medico
        FOREIGN KEY (MedicoID)
        REFERENCES clinical.Medico(MedicoID)
)
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Registro de cada consulta médica realizada.',
    @level0type = N'SCHEMA',
    @level0name = N'clinical',
    @level1type = N'TABLE',
    @level1name = N'Consulta'
GO

CREATE TABLE clinical.SignosVitales (
    SignosID               INT IDENTITY(1,1) PRIMARY KEY,
    ConsultaID             INT NOT NULL UNIQUE,
    RegistradoPorUsuarioID INT NOT NULL,
    PresionArterial        NVARCHAR(15) NULL,
    TemperaturaC           DECIMAL(4,1) NULL,
    FrecuenciaCardiaca     SMALLINT NULL,
    PesoKg                 DECIMAL(5,2) NULL,
    TallaCm                DECIMAL(5,2) NULL,
    FechaRegistro          DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_Signos_Consulta
        FOREIGN KEY (ConsultaID)
        REFERENCES clinical.Consulta(ConsultaID),

    CONSTRAINT FK_Signos_Usuario
        FOREIGN KEY (RegistradoPorUsuarioID)
        REFERENCES security.Usuario(UsuarioID)
)
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Signos vitales registrados durante la pre-consulta.',
    @level0type = N'SCHEMA',
    @level0name = N'clinical',
    @level1type = N'TABLE',
    @level1name = N'SignosVitales'
GO

CREATE TABLE clinical.Diagnostico (
    DiagnosticoID   INT IDENTITY(1,1) PRIMARY KEY,
    ConsultaID      INT NOT NULL,
    CodigoCIE10     NVARCHAR(10) NULL,
    Descripcion     NVARCHAR(500) NOT NULL,
    FechaRegistro   DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_Diagnostico_Consulta
        FOREIGN KEY (ConsultaID)
        REFERENCES clinical.Consulta(ConsultaID)
)
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Diagnósticos médicos asociados a una consulta.',
    @level0type = N'SCHEMA',
    @level0name = N'clinical',
    @level1type = N'TABLE',
    @level1name = N'Diagnostico'
GO

CREATE TABLE clinical.Tratamiento (
    TratamientoID   INT IDENTITY(1,1) PRIMARY KEY,
    DiagnosticoID   INT NOT NULL,
    Descripcion     NVARCHAR(500) NOT NULL,
    FechaInicio     DATE NOT NULL,
    FechaFin        DATE NULL,
    Estado          TINYINT NOT NULL DEFAULT 1,

    CONSTRAINT FK_Tratamiento_Diagnostico
        FOREIGN KEY (DiagnosticoID)
        REFERENCES clinical.Diagnostico(DiagnosticoID),

    CONSTRAINT CK_Tratamiento_Estado
        CHECK (Estado IN (1,2,3))
)
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Tratamientos médicos derivados de un diagnóstico.',
    @level0type = N'SCHEMA',
    @level0name = N'clinical',
    @level1type = N'TABLE',
    @level1name = N'Tratamiento'
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Estado del tratamiento: 1=Activo, 2=Finalizado, 3=Suspendido.',
    @level0type = N'SCHEMA',
    @level0name = N'clinical',
    @level1type = N'TABLE',
    @level1name = N'Tratamiento',
    @level2type = N'COLUMN',
    @level2name = N'Estado'
GO

CREATE TABLE clinical.Receta (
    RecetaID        INT IDENTITY(1,1) PRIMARY KEY,
    ConsultaID      INT NOT NULL,
    MedicoID        INT NOT NULL,
    FechaEmision    DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    Estado          TINYINT NOT NULL DEFAULT 1,

    CONSTRAINT FK_Receta_Consulta
        FOREIGN KEY (ConsultaID)
        REFERENCES clinical.Consulta(ConsultaID),

    CONSTRAINT FK_Receta_Medico
        FOREIGN KEY (MedicoID)
        REFERENCES clinical.Medico(MedicoID),

    CONSTRAINT CK_Receta_Estado
        CHECK (Estado IN (1,2,3))
)
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Recetas médicas digitales.',
    @level0type = N'SCHEMA',
    @level0name = N'clinical',
    @level1type = N'TABLE',
    @level1name = N'Receta'
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Estado de la receta: 1=Emitida, 2=Surtida, 3=Anulada.',
    @level0type = N'SCHEMA',
    @level0name = N'clinical',
    @level1type = N'TABLE',
    @level1name = N'Receta',
    @level2type = N'COLUMN',
    @level2name = N'Estado'
GO

CREATE TABLE clinical.RecetaDetalle (
    RecetaDetalleID INT IDENTITY(1,1) PRIMARY KEY,
    RecetaID        INT NOT NULL,
    Medicamento     NVARCHAR(150) NOT NULL,
    Dosis           NVARCHAR(100) NULL,
    Frecuencia      NVARCHAR(100) NULL,
    DuracionDias    SMALLINT NULL,

    CONSTRAINT FK_RecetaDetalle_Receta
        FOREIGN KEY (RecetaID)
        REFERENCES clinical.Receta(RecetaID)
)
GO

CREATE TABLE clinical.DocumentoClinico (
    DocumentoID         INT IDENTITY(1,1) PRIMARY KEY,
    ExpedienteID        INT NOT NULL,
    TipoDocumento       TINYINT NOT NULL,
    NombreArchivo       NVARCHAR(255) NOT NULL,
    RutaAlmacenamiento  NVARCHAR(500) NOT NULL,
    FechaCarga          DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_Documento_Expediente
        FOREIGN KEY (ExpedienteID)
        REFERENCES clinical.ExpedienteClinico(ExpedienteID),

    CONSTRAINT CK_Documento_Tipo
        CHECK (TipoDocumento IN (1,2,3,4))
)
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Documentos clínicos adjuntos al expediente. La ruta referencia Azure Blob Storage.',
    @level0type = N'SCHEMA',
    @level0name = N'clinical',
    @level1type = N'TABLE',
    @level1name = N'DocumentoClinico'
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Tipo de documento: 1=Laboratorio, 2=Imagenología, 3=Consentimiento Informado, 4=Otro.',
    @level0type = N'SCHEMA',
    @level0name = N'clinical',
    @level1type = N'TABLE',
    @level1name = N'DocumentoClinico',
    @level2type = N'COLUMN',
    @level2name = N'TipoDocumento'
GO

/* Inventory */

CREATE TABLE inventory.Proveedor (
    ProveedorID     INT IDENTITY(1,1) PRIMARY KEY,
    ClinicaID       INT NOT NULL,
    Nombre          NVARCHAR(150) NOT NULL,
    Categoria       TINYINT NOT NULL,
    Contacto        NVARCHAR(150) NULL,
    Telefono        NVARCHAR(30) NULL,
    Correo          NVARCHAR(150) NULL,
    Estado          TINYINT NOT NULL DEFAULT 1,

    CONSTRAINT FK_Proveedor_Clinica
        FOREIGN KEY (ClinicaID)
        REFERENCES tenant.Clinica(ClinicaID),

    CONSTRAINT CK_Proveedor_Categoria
        CHECK (Categoria IN (1,2,3,4)),

    CONSTRAINT CK_Proveedor_Estado
        CHECK (Estado IN (1,2))
)
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Proveedores de insumos y medicamentos de la clínica.',
    @level0type = N'SCHEMA',
    @level0name = N'inventory',
    @level1type = N'TABLE',
    @level1name = N'Proveedor'
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Categoría del proveedor: 1=Farmacéutico, 2=Insumos Médicos, 3=Equipo Médico, 4=Servicios Generales.',
    @level0type = N'SCHEMA',
    @level0name = N'inventory',
    @level1type = N'TABLE',
    @level1name = N'Proveedor',
    @level2type = N'COLUMN',
    @level2name = N'Categoria'
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Estado del proveedor: 1=Activo, 2=Inactivo.',
    @level0type = N'SCHEMA',
    @level0name = N'inventory',
    @level1type = N'TABLE',
    @level1name = N'Proveedor',
    @level2type = N'COLUMN',
    @level2name = N'Estado'
GO

CREATE TABLE inventory.Insumo (
    InsumoID        INT IDENTITY(1,1) PRIMARY KEY,
    ClinicaID       INT NOT NULL,
    ProveedorID     INT NULL,
    Nombre          NVARCHAR(150) NOT NULL,
    Categoria       TINYINT NOT NULL,
    UnidadMedida    NVARCHAR(30) NULL,
    StockActual     INT NOT NULL DEFAULT 0,
    StockMinimo     INT NOT NULL DEFAULT 0,

    CONSTRAINT FK_Insumo_Clinica
        FOREIGN KEY (ClinicaID)
        REFERENCES tenant.Clinica(ClinicaID),

    CONSTRAINT FK_Insumo_Proveedor
        FOREIGN KEY (ProveedorID)
        REFERENCES inventory.Proveedor(ProveedorID),

    CONSTRAINT CK_Insumo_Categoria
        CHECK (Categoria IN (1,2,3))
)
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Inventario de insumos y medicamentos de la clínica.',
    @level0type = N'SCHEMA',
    @level0name = N'inventory',
    @level1type = N'TABLE',
    @level1name = N'Insumo'
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Categoría del insumo: 1=Medicamento, 2=Material Médico, 3=Equipo Médico.',
    @level0type = N'SCHEMA',
    @level0name = N'inventory',
    @level1type = N'TABLE',
    @level1name = N'Insumo',
    @level2type = N'COLUMN',
    @level2name = N'Categoria'
GO

CREATE TABLE inventory.MovimientoInventario (
    MovimientoID    INT IDENTITY(1,1) PRIMARY KEY,
    InsumoID        INT NOT NULL,
    TipoMovimiento  TINYINT NOT NULL,
    Cantidad        INT NOT NULL,
    FechaMovimiento DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    Referencia      NVARCHAR(200) NULL,

    CONSTRAINT FK_Movimiento_Insumo
        FOREIGN KEY (InsumoID)
        REFERENCES inventory.Insumo(InsumoID),

    CONSTRAINT CK_Movimiento_Tipo
        CHECK (TipoMovimiento IN (1,2,3))
)
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Tipo de movimiento: 1=Entrada, 2=Salida, 3=Ajuste.',
    @level0type = N'SCHEMA',
    @level0name = N'inventory',
    @level1type = N'TABLE',
    @level1name = N'MovimientoInventario',
    @level2type = N'COLUMN',
    @level2name = N'TipoMovimiento'
GO

/* Audit */

CREATE TABLE audit.Auditoria (
    AuditoriaID     BIGINT IDENTITY(1,1) PRIMARY KEY,
    UsuarioID       INT NULL,
    ClinicaID       INT NULL,
    Modulo          TINYINT NOT NULL,
    Accion          TINYINT NOT NULL,
    EntidadAfectada NVARCHAR(100) NULL,
    EntidadID       INT NULL,
    DireccionIP     NVARCHAR(45) NULL,
    Resultado       TINYINT NOT NULL,
    FechaHora       DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_Auditoria_Usuario
        FOREIGN KEY (UsuarioID)
        REFERENCES security.Usuario(UsuarioID),

    CONSTRAINT FK_Auditoria_Clinica
        FOREIGN KEY (ClinicaID)
        REFERENCES tenant.Clinica(ClinicaID),

    CONSTRAINT CK_Auditoria_Modulo
        CHECK (Modulo BETWEEN 1 AND 7),

    CONSTRAINT CK_Auditoria_Accion
        CHECK (Accion BETWEEN 1 AND 4),

    CONSTRAINT CK_Auditoria_Resultado
        CHECK (Resultado IN (1,2))
)
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Registro de auditoría de accesos, modificaciones y eliminaciones sobre información sensible.',
    @level0type = N'SCHEMA',
    @level0name = N'audit',
    @level1type = N'TABLE',
    @level1name = N'Auditoria'
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Módulo auditado: 1=Pacientes, 2=Citas Médicas, 3=Expedientes Clínicos, 4=Usuarios y Roles, 5=Tenants y Clínicas, 6=Facturación, 7=Proveedores e Inventario.',
    @level0type = N'SCHEMA',
    @level0name = N'audit',
    @level1type = N'TABLE',
    @level1name = N'Auditoria',
    @level2type = N'COLUMN',
    @level2name = N'Modulo'
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Acción realizada: 1=Consulta, 2=Creación, 3=Modificación, 4=Eliminación.',
    @level0type = N'SCHEMA',
    @level0name = N'audit',
    @level1type = N'TABLE',
    @level1name = N'Auditoria',
    @level2type = N'COLUMN',
    @level2name = N'Accion'
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Resultado del evento: 1=Exitoso, 2=Fallido.',
    @level0type = N'SCHEMA',
    @level0name = N'audit',
    @level1type = N'TABLE',
    @level1name = N'Auditoria',
    @level2type = N'COLUMN',
    @level2name = N'Resultado'
GO

/* Índices */

CREATE INDEX IX_CitaMedica_Fecha
ON clinical.CitaMedica (ClinicaID, FechaHora)
GO

CREATE INDEX IX_Paciente_Clinica
ON clinical.Paciente (ClinicaID)
GO

CREATE INDEX IX_Auditoria_Fecha
ON audit.Auditoria (FechaHora)
GO

CREATE INDEX IX_Usuario_Clinica
ON security.Usuario (ClinicaID)
GO

CREATE INDEX IX_Factura_Clinica
ON billing.Factura (ClinicaID)
GO

CREATE INDEX IX_Medico_Clinica
ON clinical.Medico (ClinicaID)
GO

CREATE INDEX IX_Proveedor_Clinica
ON inventory.Proveedor (ClinicaID)
GO

CREATE INDEX IX_Insumo_Clinica
ON inventory.Insumo (ClinicaID)
GO