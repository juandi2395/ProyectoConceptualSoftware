-- 1. Creacion de la base de datos

CREATE DATABASE CooperativaPrestamos;

USE CooperativaPrestamos;
GO

-- 2. Creacion del esquema Core

EXEC (N'CREATE SCHEMA Core');
GO

-- 3. Creacion de las tablas

-- Estados
CREATE TABLE Core.Estados (
    idEstado INT PRIMARY KEY IDENTITY,
    nombreEstado VARCHAR(50) NOT NULL,
    descripcionEstado VARCHAR(255) NULL,
    CONSTRAINT UQ_NombreEstado UNIQUE (nombreEstado)
);
GO

-- Nivel de aprobacion
CREATE TABLE Core.NivelAprobacion (
    idNivel INT PRIMARY KEY IDENTITY,
    nombreNivel VARCHAR(50) NOT NULL,
    montoMinimo DECIMAL(10, 2) NOT NULL,
    montoMaximo DECIMAL(10, 2) NOT NULL,
    diasMaximosAprobacion INT NOT NULL,
    requireEntrevista BIT NOT NULL,
    CONSTRAINT UQ_NombreNivel UNIQUE (nombreNivel)
);
GO


-- Cliente
CREATE TABLE Core.Cliente (
    idCliente INT PRIMARY KEY IDENTITY,
    nombreCliente VARCHAR(100) NOT NULL,
    apellidoCliente VARCHAR(100) NOT NULL,
    fechaNacimiento DATE NOT NULL,
    direccionCliente VARCHAR(255) NOT NULL,
    telefonoCliente VARCHAR(20) NOT NULL,
    emailCliente VARCHAR(100) NOT NULL,
    CONSTRAINT UQ_EmailCliente UNIQUE (emailCliente)
);
GO

-- Departamento
CREATE TABLE Core.Departamento (
    idDepartamento INT PRIMARY KEY IDENTITY,
    nombreDepartamento VARCHAR(100) NOT NULL,
    descripcionDepartamento VARCHAR(255) NULL,
    CONSTRAINT UQ_NombreDepartamento UNIQUE (nombreDepartamento)
);
GO

-- Empleado
CREATE TABLE Core.Empleado (
    idEmpleado INT PRIMARY KEY IDENTITY,
    nombreEmpleado VARCHAR(100) NOT NULL,
    apellidoEmpleado VARCHAR(100) NOT NULL,
    fechaContratacion DATE NOT NULL,
    idDepartamento INT NOT NULL,
    CONSTRAINT FK_Empleado_Departamento FOREIGN KEY (idDepartamento) REFERENCES Core.Departamento(idDepartamento)
);
GO

-- Cuenta Cliente
CREATE TABLE Core.CuentaCliente (
    idCuenta INT PRIMARY KEY IDENTITY,
    idCliente INT NOT NULL,
    saldo DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    fechaCreacion DATE NOT NULL,
    CONSTRAINT FK_CuentaCliente_Cliente FOREIGN KEY (idCliente) REFERENCES Core.Cliente(idCliente)
);
GO

-- Solicitud de Prestamo
CREATE TABLE Core.SolicitudPrestamo (
    idSolicitud INT PRIMARY KEY IDENTITY,
    idCliente INT NOT NULL,
    idCuenta INT NOT NULL,
    idDepartamento INT NOT NULL,
    idNivel INT NOT NULL,    
    estadoSolicitud VARCHAR(50) NOT NULL,
    montoSolicitado DECIMAL(10, 2) NOT NULL,
    fechaSolicitud DATE NOT NULL,
    fechaActualizacion DATE NOT NULL,
    fechaLimiteDocumentacion DATE NOT NULL,
    fechaAprobacion DATE NULL,
    CONSTRAINT FK_SolicitudPrestamo_Cliente FOREIGN KEY (idCliente) REFERENCES Core.Cliente(idCliente),
    CONSTRAINT FK_SolicitudPrestamo_CuentaCliente FOREIGN KEY (idCuenta) REFERENCES Core.CuentaCliente(idCuenta),
    CONSTRAINT FK_SolicitudPrestamo_Departamento FOREIGN KEY (idDepartamento) REFERENCES Core.Departamento(idDepartamento),
    CONSTRAINT FK_SolicitudPrestamo_NivelAprobacion FOREIGN KEY (idNivel) REFERENCES Core.NivelAprobacion(idNivel)
);
GO

-- Documentacion de Solicitud
CREATE TABLE Core.DocumentacionSolicitud (
    idDocumentacion INT PRIMARY KEY IDENTITY,
    idSolicitud INT NOT NULL,
    nombreDocumento VARCHAR(100) NOT NULL,
    fechaEntrega DATE NOT NULL,
    fechaRevision DATE NULL,
    CONSTRAINT FK_DocumentacionSolicitud_SolicitudPrestamo FOREIGN KEY (idSolicitud) REFERENCES Core.SolicitudPrestamo(idSolicitud)
);
GO


-- Estudio Solicitud
CREATE TABLE Core.EstudioSolicitud (
    idEstudio INT PRIMARY KEY IDENTITY,
    idSolicitud INT NOT NULL,
    idEmpleado INT NOT NULL,
    fechaInicio DATE NOT NULL,
    fechaFin DATE NULL,
    observaciones VARCHAR(255) NOT NULL,
    CONSTRAINT FK_EstudioSolicitud_SolicitudPrestamo FOREIGN KEY (idSolicitud) REFERENCES Core.SolicitudPrestamo(idSolicitud),
    CONSTRAINT FK_EstudioSolicitud_Empleado FOREIGN KEY (idEmpleado) REFERENCES Core.Empleado(idEmpleado)
);
GO

-- Entevista Solicitud
CREATE TABLE Core.EntrevistaSolicitud (
    idEntrevista INT PRIMARY KEY IDENTITY,
    idSolicitud INT NOT NULL,
    idEmpleado INT NOT NULL,
    fechaEntrevista DATE NOT NULL,
    acuerdos VARCHAR(255) NOT NULL,
    CONSTRAINT FK_EntrevistaSolicitud_SolicitudPrestamo FOREIGN KEY (idSolicitud) REFERENCES Core.SolicitudPrestamo(idSolicitud),
    CONSTRAINT FK_EntrevistaSolicitud_Empleado FOREIGN KEY (idEmpleado) REFERENCES Core.Empleado(idEmpleado)
);
GO

-- Depósito de Prestamo
CREATE TABLE Core.DepositoPrestamo (
    idDeposito INT PRIMARY KEY IDENTITY,
    idSolicitud INT NOT NULL,
    idCuenta INT NOT NULL,
    montoDeposito DECIMAL(10, 2) NOT NULL,
    fechaDeposito DATE NOT NULL,
    CONSTRAINT FK_DepositoPrestamo_SolicitudPrestamo FOREIGN KEY (idSolicitud) REFERENCES Core.SolicitudPrestamo(idSolicitud),
    CONSTRAINT FK_DepositoPrestamo_CuentaCliente FOREIGN KEY (idCuenta) REFERENCES Core.CuentaCliente(idCuenta)
);
GO

-- 4. Propiedades extendidas 

-- Base de datos
EXEC sys.sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'Base de datos para la gestion de prestamos de la cooperativa', 
    @level0type = N'SCHEMA',
    @level0name = 'Core';
GO

-- Tablas
EXEC sys.sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'Tabla que almacena los estados de las solicitudes de prestamo', 
    @level0type = N'SCHEMA',
    @level0name = 'Core',
    @level1type = N'TABLE',
    @level1name = 'Estados';
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description', 
    @value = N'Tabla que almacena los niveles de aprobacion de las solicitudes de prestamo', 
    @level0type = N'SCHEMA',
    @level0name = 'Core',
    @level1type = N'TABLE',
    @level1name = 'NivelAprobacion';
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description', 
    @value = N'Tabla que almacena la informacion de los clientes de la cooperativa', 
    @level0type = N'SCHEMA',
    @level0name = 'Core',
    @level1type = N'TABLE',
    @level1name = 'Cliente';
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description', 
    @value = N'Tabla que almacena la informacion de los departamentos de la cooperativa', 
    @level0type = N'SCHEMA',
    @level0name = 'Core',
    @level1type = N'TABLE',
    @level1name = 'Departamento';
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description', 
    @value = N'Tabla que almacena la informacion de los empleados de la cooperativa', 
    @level0type = N'SCHEMA',
    @level0name = 'Core',
    @level1type = N'TABLE',
    @level1name = 'Empleado';
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description', 
    @value = N'Tabla que almacena la informacion de las cuentas de los clientes de la cooperativa', 
    @level0type = N'SCHEMA',
    @level0name = 'Core',
    @level1type = N'TABLE',
    @level1name = 'CuentaCliente';
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description', 
    @value = N'Tabla que almacena la informacion de las solicitudes de prestamo de los clientes de la cooperativa', 
    @level0type = N'SCHEMA',
    @level0name = 'Core',
    @level1type = N'TABLE',
    @level1name = 'SolicitudPrestamo';
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description', 
    @value = N'Tabla que almacena la informacion de la documentacion requerida para las solicitudes de prestamo', 
    @level0type = N'SCHEMA',
    @level0name = 'Core',
    @level1type = N'TABLE',
    @level1name = 'DocumentacionSolicitud';
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description', 
    @value = N'Tabla que almacena la informacion de los estudios realizados a las solicitudes de prestamo', 
    @level0type = N'SCHEMA',
    @level0name = 'Core',
    @level1type = N'TABLE',
    @level1name = 'EstudioSolicitud';
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description', 
    @value = N'Tabla que almacena la informacion de las entrevistas realizadas a las solicitudes de prestamo', 
    @level0type = N'SCHEMA',
    @level0name = 'Core',
    @level1type = N'TABLE',
    @level1name = 'EntrevistaSolicitud';
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description', 
    @value = N'Tabla que almacena la informacion de los depositos realizados a las solicitudes de prestamo', 
    @level0type = N'SCHEMA',
    @level0name = 'Core',
    @level1type = N'TABLE',
    @level1name = 'DepositoPrestamo';
GO

-- Columnas relevantes
EXEC sys.sp_addextendedproperty
    @name = N'MS_Description', 
    @value = N'Nombre del estado de la solicitud de prestamo', 
    @level0type = N'SCHEMA',
    @level0name = 'Core',
    @level1type = N'TABLE',
    @level1name = 'Estados',
    @level2type = N'COLUMN',
    @level2name = 'nombreEstado';
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description', 
    @value = N'Monto minimo para el nivel de aprobacion', 
    @level0type = N'SCHEMA',
    @level0name = 'Core',
    @level1type = N'TABLE',
    @level1name = 'NivelAprobacion',
    @level2type = N'COLUMN',
    @level2name = 'montoMinimo';
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description', 
    @value = N'Monto maximo para el nivel de aprobacion', 
    @level0type = N'SCHEMA',
    @level0name = 'Core',
    @level1type = N'TABLE',
    @level1name = 'NivelAprobacion',
    @level2type = N'COLUMN',
    @level2name = 'montoMaximo';
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description', 
    @value = N'Cantidad de dias maximos para aprobar la solicitud de prestamo', 
    @level0type = N'SCHEMA',
    @level0name = 'Core',
    @level1type = N'TABLE',
    @level1name = 'NivelAprobacion',
    @level2type = N'COLUMN',
    @level2name = 'diasMaximosAprobacion';
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description', 
    @value = N'Indica si el nivel de aprobacion requiere entrevista', 
    @level0type = N'SCHEMA',
    @level0name = 'Core',
    @level1type = N'TABLE',
    @level1name = 'NivelAprobacion',
    @level2type = N'COLUMN',
    @level2name = 'requireEntrevista';
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description', 
    @value = N'Observaciones realizadas durante el estudio de la solicitud de prestamo', 
    @level0type = N'SCHEMA',
    @level0name = 'Core',
    @level1type = N'TABLE',
    @level1name = 'EstudioSolicitud',
    @level2type = N'COLUMN',
    @level2name = 'observaciones';
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description', 
    @value = N'Acuerdos realizados durante la entrevista de la solicitud de prestamo', 
    @level0type = N'SCHEMA',
    @level0name = 'Core',
    @level1type = N'TABLE',
    @level1name = 'EntrevistaSolicitud',
    @level2type = N'COLUMN',
    @level2name = 'acuerdos';
GO