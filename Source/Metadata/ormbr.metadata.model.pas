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

unit ormbr.metadata.model;

interface

uses
  SysUtils,
  ormbr.metadata.extract,
  ormbr.metadata.register,
  ormbr.database.mapping,
  ormbr.mapping.classes,
  ormbr.mapping.explorer,
  ormbr.factory.interfaces;

type
  TModelMetadata = class(TModelMetadataAbstract)
  public
    procedure GetCatalogs; override;
    procedure GetSchemas; override;
    procedure GetTables; override;
    procedure GetColumns(ATable: TTableMIK; AClass: TClass); override;
    procedure GetPrimaryKey(ATable: TTableMIK; AClass: TClass); override;
    procedure GetIndexeKeys(ATable: TTableMIK; AClass: TClass); override;
    procedure GetForeignKeys(ATable: TTableMIK; AClass: TClass); override;
    procedure GetChecks(ATable: TTableMIK; AClass: TClass); override;
    procedure GetSequences; override;
    procedure GetProcedures; override;
    procedure GetFunctions; override;
    procedure GetViews; override;
    procedure GetTriggers; override;
    procedure GetModelMetadata; override;
  end;

implementation

{ TModelMetadata }

procedure TModelMetadata.GetModelMetadata;
begin
  GetCatalogs;
end;

procedure TModelMetadata.GetCatalogs;
begin
  FCatalogMetadata.Name := '';
  GetSchemas;
end;

procedure TModelMetadata.GetSchemas;
begin
  FCatalogMetadata.Schema := '';
  GetSequences;
  GetTables;
end;

procedure TModelMetadata.GetTables;
var
  oClass: TClass;
  oTable: TTableMIK;
  oTableMap: TTableMapping;
begin
  for oClass in TMappingExplorer.GetInstance.Repository.List.Entitys do
  begin
    oTableMap := TMappingExplorer.GetInstance.GetMappingTable(oClass);
    if oTableMap <> nil then
    begin
      oTable := TTableMIK.Create(FCatalogMetadata);
      oTable.Name := oTableMap.Name;
      oTable.Description := oTableMap.Description;
      /// <summary>
      /// Extrair colunas
      /// </summary>
      GetColumns(oTable, oClass);
      /// <summary>
      /// Extrair Primary Key
      /// </summary>
      GetPrimaryKey(oTable, oClass);
      /// <summary>
      /// Extrair Foreign Keys
      /// </summary>
      GetForeignKeys(oTable, oClass);
      /// <summary>
      /// Extrair Indexes
      /// </summary>
      GetIndexeKeys(oTable, oClass);
      /// <summary>
      /// Extrair Indexes
      /// </summary>
      GetChecks(oTable, oClass);
      /// <summary>
      /// Adiciona na lista de tabelas extraidas
      /// </summary>
      FCatalogMetadata.Tables.Add(UpperCase(oTable.Name), oTable);
    end;
  end;
end;

procedure TModelMetadata.GetChecks(ATable: TTableMIK; AClass: TClass);
var
  oCheck: TCheckMIK;
  oCheckMapList: TCheckMappingList;
  oCheckMap: TCheckMapping;
begin
  oCheckMapList := TMappingExplorer.GetInstance.GetMappingCheck(AClass);
  if oCheckMapList <> nil then
  begin
    for oCheckMap in oCheckMapList do
    begin
      oCheck := TCheckMIK.Create(ATable);
      oCheck.Name := oCheckMap.Name;
      oCheck.Condition := oCheckMap.Condition;
      oCheck.Description := '';
      ATable.Checks.Add(UpperCase(oCheck.Name), oCheck);
    end;
  end;
end;

procedure TModelMetadata.GetColumns(ATable: TTableMIK; AClass: TClass);
var
  oColumn: TColumnMIK;
  oColumnMap: TColumnMapping;
  oColumnMapList: TColumnMappingList;
begin
  oColumnMapList := TMappingExplorer.GetInstance.GetMappingColumn(AClass);
  if oColumnMapList <> nil then
  begin
    for oColumnMap in oColumnMapList do
    begin
      oColumn := TColumnMIK.Create(ATable);
      oColumn.Name := oColumnMap.ColumnName;
      oColumn.Description := oColumnMap.Description;
      oColumn.Position := oColumnMap.FieldIndex;
      oColumn.NotNull := oColumnMap.IsNotNull;
      oColumn.DefaultValue := oColumnMap.DefaultValue;
      oColumn.Size := oColumnMap.Size;
      oColumn.Precision := oColumnMap.Precision;
      oColumn.Scale := oColumnMap.Scale;
      oColumn.FieldType := oColumnMap.FieldType;
      /// <summary>
      /// Resolve Field Type
      /// </summary>
      GetFieldTypeDefinition(oColumn);
      try
        ATable.Fields.Add(FormatFloat('000000', oColumn.Position), oColumn);
      except
        on E: Exception do
        begin
          raise Exception.Create('ORMBr Erro in GetColumns() : '  + sLineBreak +
                                 'Table  : [' + ATable.Name  + ']' + sLineBreak +
                                 'Column : [' + oColumn.Name + ']' + sLineBreak +
                                 'Message: [' + e.Message + ']');
        end;
      end;
    end;
  end;
end;

procedure TModelMetadata.GetForeignKeys(ATable: TTableMIK; AClass: TClass);
var
  oForeignKey: TForeignKeyMIK;
  oForeignKeyMapList: TForeignKeyMappingList;
  oForeignKeyMap: TForeignKeyMapping;

  procedure GetForeignKeyColumns(AForeignKey: TForeignKeyMIK);
  var
    oFromField: TColumnMIK;
    oToField: TColumnMIK;
    iFor: Integer;
  begin
    /// FromColumns
    for iFor := 0 to oForeignKeyMap.FromColumns.Count -1 do
    begin
      oFromField := TColumnMIK.Create(ATable);
      oFromField.Name := oForeignKeyMap.FromColumns[iFor];
      oFromField.Description := oForeignKeyMap.Description;
      oFromField.Position := iFor;
      AForeignKey.FromFields.Add(FormatFloat('000000', oFromField.Position), oFromField);
    end;
    /// ToColumns
    for iFor := 0 to oForeignKeyMap.ToColumns.Count -1 do
    begin
      oToField := TColumnMIK.Create(ATable);
      oToField.Name := oForeignKeyMap.ToColumns[iFor];
      oToField.Description := oForeignKeyMap.Description;
      oToField.Position := iFor;
      AForeignKey.ToFields.Add(FormatFloat('000000', oToField.Position), oToField);
    end;
  end;

begin
  oForeignKeyMapList := TMappingExplorer.GetInstance.GetMappingForeignKey(AClass);
  if oForeignKeyMapList <> nil then
  begin
    for oForeignKeyMap in oForeignKeyMapList do
    begin
      oForeignKey := TForeignKeyMIK.Create(ATable);
      oForeignKey.Name := oForeignKeyMap.Name;
      oForeignKey.FromTable := oForeignKeyMap.TableNameRef;
      oForeignKey.OnUpdate := oForeignKeyMap.RuleUpdate;
      oForeignKey.OnDelete := oForeignKeyMap.RuleDelete;
      oForeignKey.Description := oForeignKeyMap.Description;
      ATable.ForeignKeys.Add(UpperCase(oForeignKey.Name), oForeignKey);
      /// <summary>
      /// Estrai as columnas da indexe key
      /// </summary>
      GetForeignKeyColumns(oForeignKey);
    end;
  end;
end;

procedure TModelMetadata.GetFunctions;
begin

end;

procedure TModelMetadata.GetPrimaryKey(ATable: TTableMIK; AClass: TClass);
var
  oPrimaryKeyMap: TPrimaryKeyMapping;

  procedure GetPrimaryKeyColumns(APrimaryKey: TPrimaryKeyMIK);
  var
    oColumn: TColumnMIK;
    iFor: Integer;
  begin
    for iFor := 0 to oPrimaryKeyMap.Columns.Count -1 do
    begin
      oColumn := TColumnMIK.Create(ATable);
      oColumn.Name := oPrimaryKeyMap.Columns[iFor];
      oColumn.Description := oPrimaryKeyMap.Description;
      oColumn.SortingOrder := oPrimaryKeyMap.SortingOrder;
      oColumn.AutoIncrement := oPrimaryKeyMap.AutoIncrement;
      oColumn.Position := iFor;
      APrimaryKey.Fields.Add(FormatFloat('000000', oColumn.Position), oColumn);
    end;
  end;

begin
  oPrimaryKeyMap := TMappingExplorer.GetInstance.GetMappingPrimaryKey(AClass);
  if oPrimaryKeyMap <> nil then
  begin
    ATable.PrimaryKey.Name := Format('PK_%s', [ATable.Name]);
    ATable.PrimaryKey.Description := oPrimaryKeyMap.Description;
    ATable.PrimaryKey.AutoIncrement := oPrimaryKeyMap.AutoIncrement;
    /// <summary>
    /// Estrai as columnas da primary key
    /// </summary>
    GetPrimaryKeyColumns(ATable.PrimaryKey);
  end;
end;

procedure TModelMetadata.GetProcedures;
begin

end;

procedure TModelMetadata.GetSequences;
var
  oClass: TClass;
  oSequence: TSequenceMIK;
  oSequenceMap: TSequenceMapping;
begin
  for oClass in TMappingExplorer.GetInstance.Repository.List.Entitys do
  begin
    oSequenceMap := TMappingExplorer.GetInstance.GetMappingSequence(oClass);
    if oSequenceMap <> nil then
    begin
      oSequence := TSequenceMIK.Create(FCatalogMetadata);
      oSequence.TableName := oSequenceMap.TableName;
      oSequence.Name := oSequenceMap.Name;
      oSequence.Description := oSequenceMap.Description;
      oSequence.InitialValue := oSequenceMap.Initial;
      oSequence.Increment := oSequenceMap.Increment;
      if FConnection.GetDriverName = dnMySQL then
        FCatalogMetadata.Sequences.Add(UpperCase(oSequence.TableName), oSequence)
      else
        FCatalogMetadata.Sequences.Add(UpperCase(oSequence.Name), oSequence);
    end;
  end;
end;

procedure TModelMetadata.GetTriggers;
begin

end;

procedure TModelMetadata.GetIndexeKeys(ATable: TTableMIK; AClass: TClass);
var
  oIndexeKey: TIndexeKeyMIK;
  oIndexeKeyMapList: TIndexeMappingList;
  oIndexeKeyMap: TIndexeMapping;

  procedure GetIndexeKeyColumns(AIndexeKey: TIndexeKeyMIK);
  var
    oColumn: TColumnMIK;
    iFor: Integer;
  begin
    for iFor := 0 to oIndexeKeyMap.Columns.Count -1 do
    begin
      oColumn := TColumnMIK.Create(ATable);
      oColumn.Name := oIndexeKeyMap.Columns[iFor];
      oColumn.Description := oIndexeKeyMap.Description;
      oColumn.SortingOrder := oIndexeKeyMap.SortingOrder;
      oColumn.Position := iFor;
      AIndexeKey.Fields.Add(FormatFloat('000000', oColumn.Position), oColumn);
    end;
  end;

begin
  oIndexeKeyMapList := TMappingExplorer.GetInstance.GetMappingIndexe(AClass);
  if oIndexeKeyMapList <> nil then
  begin
    for oIndexeKeyMap in oIndexeKeyMapList do
    begin
      oIndexeKey := TIndexeKeyMIK.Create(ATable);
      oIndexeKey.Name := oIndexeKeyMap.Name;
      oIndexeKey.Unique := oIndexeKeyMap.Unique;
      oIndexeKey.Description := '';
      ATable.IndexeKeys.Add(UpperCase(oIndexeKey.Name), oIndexeKey);
      /// <summary>
      /// Estrai as columnas da indexe key
      /// </summary>
      GetIndexeKeyColumns(oIndexeKey);
    end;
  end;
end;

procedure TModelMetadata.GetViews;
begin

end;

end.
