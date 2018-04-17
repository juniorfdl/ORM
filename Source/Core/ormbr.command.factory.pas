{
      ORM Brasil é um ORM simples e descomplicado para quem utiliza Delphi

                   Copyright (c) 2016, Isaque Pinheiro
                          All rights reserved.

                    GNU Lesser General Public License
                      Versão 3, 29 de junho de 2007

       Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>
       A todos é permitido copiar e distribuir cópias deste documento de
       licença, mas mudá-lo não é permitido.

       Esta versão da GNU Lesser General Public License incorpora
       os termos e condições da versão 3 da GNU General Public License
       Licença, complementado pelas permissões adicionais listadas no
       arquivo LICENSE na pasta principal.
}

{ @abstract(ORMBr Framework.)
  @created(20 Jul 2016)
  @author(Isaque Pinheiro <isaquepsp@gmail.com>)
  @author(Skype : ispinheiro)

  ORM Brasil é um ORM simples e descomplicado para quem utiliza Delphi.
}

unit ormbr.command.factory;

interface

uses
  DB,
  Rtti,
  Generics.Collections,
  ormbr.criteria,
  ormbr.types.mapping,
  ormbr.factory.interfaces,
  ormbr.mapping.classes,
  ormbr.dml.generator,
  ormbr.command.selecter,
  ormbr.command.inserter,
  ormbr.command.deleter,
  ormbr.command.updater,
  ormbr.Types.database;

type
  TDMLCommandFactoryAbstract = class abstract
  protected
    FDMLCommand: string;
  public
    constructor Create(const AObject: TObject; const AConnection: IDBConnection; const ADriverName: TDriverName); virtual; abstract;
    function GeneratorSelectAll(AClass: TClass; APageSize: Integer): IDBResultSet; virtual; abstract;
    function GeneratorSelectID(AClass: TClass; AID: Variant): IDBResultSet; virtual; abstract;
    function GeneratorSelect(ASQL: String; APageSize: Integer): IDBResultSet; virtual; abstract;
    function GeneratorSelectOneToOne(const AOwner: TObject; const AClass: TClass;
      const AAssociation: TAssociationMapping): IDBResultSet; virtual; abstract;
    function GeneratorSelectOneToMany(const AOwner: TObject; const AClass: TClass;
      const AAssociation: TAssociationMapping): IDBResultSet; virtual; abstract;
    function GeneratorSelectWhere(const AClass: TClass; const AWhere: string;
      const AOrderBy: string; const APageSize: Integer): string; virtual; abstract;
    function GeneratorNextPacket: IDBResultSet; virtual; abstract;
    function GetDMLCommand: string; virtual; abstract;
    function ExistSequence: Boolean; virtual; abstract;
    procedure GeneratorUpdate(const AObject: TObject; const AModifiedFields: TList<string>); virtual; abstract;
    procedure GeneratorInsert(const AObject: TObject); virtual; abstract;
    procedure GeneratorDelete(const AObject: TObject); virtual; abstract;
  end;

  TDMLCommandFactory = class(TDMLCommandFactoryAbstract)
  protected
    FConnection: IDBConnection;
    FCommandSelecter: TCommandSelecter;
    FCommandInserter: TCommandInserter;
    FCommandUpdater: TCommandUpdater;
    FCommandDeleter: TCommandDeleter;
  public
    constructor Create(const AObject: TObject; const AConnection: IDBConnection; const ADriverName: TDriverName); override;
    destructor Destroy; override;
    function GeneratorSelectAll(AClass: TClass; APageSize: Integer): IDBResultSet; override;
    function GeneratorSelectID(AClass: TClass; AID: Variant): IDBResultSet; override;
    function GeneratorSelect(ASQL: String; APageSize: Integer): IDBResultSet; override;
    function GeneratorSelectOneToOne(const AOwner: TObject; const AClass: TClass;
      const AAssociation: TAssociationMapping): IDBResultSet; override;
    function GeneratorSelectOneToMany(const AOwner: TObject; const AClass: TClass;
      const AAssociation: TAssociationMapping): IDBResultSet; override;
    function GeneratorSelectWhere(const AClass: TClass; const AWhere: string;
      const AOrderBy: string; const APageSize: Integer): string; override;
    function GeneratorNextPacket: IDBResultSet; override;
    function GetDMLCommand: string; override;
    function ExistSequence: Boolean; override;
    procedure GeneratorUpdate(const AObject: TObject; const AModifiedFields: TList<string>); override;
    procedure GeneratorInsert(const AObject: TObject); override;
    procedure GeneratorDelete(const AObject: TObject); override;
  end;

implementation

uses
  ormbr.objects.helper,
  ormbr.rtti.helper;

{ TDMLCommandFactory }

constructor TDMLCommandFactory.Create(const AObject: TObject;
  const AConnection: IDBConnection; const ADriverName: TDriverName);
begin
  FConnection := AConnection;
  FCommandSelecter := TCommandSelecter.Create(AConnection, ADriverName, AObject);
  FCommandInserter := TCommandInserter.Create(AConnection, ADriverName, AObject);
  FCommandUpdater  := TCommandUpdater.Create(AConnection, ADriverName, AObject);
  FCommandDeleter  := TCommandDeleter.Create(AConnection, ADriverName, AObject);
end;

destructor TDMLCommandFactory.Destroy;
begin
  FCommandSelecter.Free;
  FCommandDeleter.Free;
  FCommandInserter.Free;
  FCommandUpdater.Free;
  inherited;
end;

function TDMLCommandFactory.GetDMLCommand: string;
begin
  Result := FDMLCommand;
end;

function TDMLCommandFactory.ExistSequence: Boolean;
begin
  if FCommandInserter.Sequence <> nil then
    Exit(FCommandInserter.Sequence.ExistSequence)
  else
    Exit(False)
end;

procedure TDMLCommandFactory.GeneratorDelete(const AObject: TObject);
begin
  FConnection.ExecuteDirect(FCommandDeleter.GenerateDelete(AObject), FCommandDeleter.Params);
  FDMLCommand := FCommandDeleter.GetDMLCommand;
  /// <summary>
  /// Envia comando para tela do monitor.
  /// </summary>
  if FConnection.CommandMonitor <> nil then
    FConnection.CommandMonitor.Command(FDMLCommand, FCommandDeleter.Params);
end;

procedure TDMLCommandFactory.GeneratorInsert(const AObject: TObject);
begin
  FConnection.ExecuteDirect(FCommandInserter.GenerateInsert(AObject), FCommandInserter.Params);
  FDMLCommand := FCommandInserter.GetDMLCommand;
  /// <summary>
  /// Envia comando para tela do monitor.
  /// </summary>
  if FConnection.CommandMonitor <> nil then
    FConnection.CommandMonitor.Command(FDMLCommand, FCommandInserter.Params);
end;

function TDMLCommandFactory.GeneratorSelect(ASQL: String; APageSize: Integer): IDBResultSet;
begin
  FCommandSelecter.SetPageSize(APageSize);
  Result := FConnection.ExecuteSQL(ASQL);
  FDMLCommand := ASQL;
  /// <summary>
  /// Envia comando para tela do monitor.
  /// </summary>
  if FConnection.CommandMonitor <> nil then
    FConnection.CommandMonitor.Command(FDMLCommand, FCommandSelecter.Params);
end;

function TDMLCommandFactory.GeneratorSelectAll(AClass: TClass; APageSize: Integer): IDBResultSet;
begin
  FCommandSelecter.SetPageSize(APageSize);
  Result := FConnection.ExecuteSQL(FCommandSelecter.GenerateSelectAll(AClass));
  FDMLCommand := FCommandSelecter.GetDMLCommand;
  /// <summary>
  /// Envia comando para tela do monitor.
  /// </summary>
  if FConnection.CommandMonitor <> nil then
    FConnection.CommandMonitor.Command(FDMLCommand, FCommandSelecter.Params);
end;

function TDMLCommandFactory.GeneratorSelectOneToMany(const AOwner: TObject;
  const AClass: TClass; const AAssociation: TAssociationMapping): IDBResultSet;
begin
  Result := FConnection.ExecuteSQL(FCommandSelecter.GenerateSelectOneToMany(AOwner, AClass, AAssociation));
  FDMLCommand := FCommandSelecter.GetDMLCommand;
  /// <summary>
  /// Envia comando para tela do monitor.
  /// </summary>
  if FConnection.CommandMonitor <> nil then
    FConnection.CommandMonitor.Command(FDMLCommand, FCommandSelecter.Params);
end;

function TDMLCommandFactory.GeneratorSelectOneToOne(const AOwner: TObject;
  const AClass: TClass; const AAssociation: TAssociationMapping): IDBResultSet;
begin
  Result := FConnection.ExecuteSQL(FCommandSelecter.GenerateSelectOneToOne(AOwner, AClass, AAssociation));
  FDMLCommand := FCommandSelecter.GetDMLCommand;
  /// <summary>
  /// Envia comando para tela do monitor.
  /// </summary>
  if FConnection.CommandMonitor <> nil then
    FConnection.CommandMonitor.Command(FDMLCommand, FCommandSelecter.Params);
end;

function TDMLCommandFactory.GeneratorSelectWhere(const AClass: TClass;
  const AWhere: string; const AOrderBy: string; const APageSize: Integer): string;
begin
  FCommandSelecter.SetPageSize(APageSize);
  Result := FCommandSelecter.GeneratorSelectWhere(AClass, AWhere, AOrderBy);
end;

function TDMLCommandFactory.GeneratorSelectID(AClass: TClass; AID: Variant): IDBResultSet;
begin
  Result := FConnection.ExecuteSQL(FCommandSelecter.GenerateSelectID(AClass, AID));
  FDMLCommand := FCommandSelecter.GetDMLCommand;
  /// <summary>
  /// Envia comando para tela do monitor.
  /// </summary>
  if FConnection.CommandMonitor <> nil then
    FConnection.CommandMonitor.Command(FDMLCommand, FCommandSelecter.Params);
end;

function TDMLCommandFactory.GeneratorNextPacket: IDBResultSet;
begin
  Result := FConnection.ExecuteSQL(FCommandSelecter.GenerateNextPacket);
  FDMLCommand := FCommandSelecter.GetDMLCommand;
  /// <summary>
  /// Envia comando para tela do monitor.
  /// </summary>
  if FConnection.CommandMonitor <> nil then
    FConnection.CommandMonitor.Command(FDMLCommand, FCommandSelecter.Params);
end;

procedure TDMLCommandFactory.GeneratorUpdate(const AObject: TObject;
  const AModifiedFields: TList<string>);
begin
  if AModifiedFields.Count > 0 then
  begin
    FConnection.ExecuteDirect(FCommandUpdater.GenerateUpdate(AObject, AModifiedFields), FCommandUpdater.Params);
    FDMLCommand := FCommandUpdater.GetDMLCommand;
    /// <summary>
    /// Envia comando para tela do monitor.
    /// </summary>
    if FConnection.CommandMonitor <> nil then
      FConnection.CommandMonitor.Command(FDMLCommand, FCommandUpdater.Params);
  end;
end;

end.
