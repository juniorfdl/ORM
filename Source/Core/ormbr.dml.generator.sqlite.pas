{
      ORM Brasil � um ORM simples e descomplicado para quem utiliza Delphi

                   Copyright (c) 2016, Isaque Pinheiro
                          All rights reserved.

                    GNU Lesser General Public License
                      Vers�o 3, 29 de junho de 2007

       Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>
       A todos � permitido copiar e distribuir c�pias deste documento de
       licen�a, mas mud�-lo n�o � permitido.

       Esta vers�o da GNU Lesser General Public License incorpora
       os termos e condi��es da vers�o 3 da GNU General Public License
       Licen�a, complementado pelas permiss�es adicionais listadas no
       arquivo LICENSE na pasta principal.
}

{ @abstract(ORMBr Framework.)
  @created(20 Jul 2016)
  @author(Isaque Pinheiro <isaquepsp@gmail.com>)
  @author(Skype : ispinheiro)

  ORM Brasil � um ORM simples e descomplicado para quem utiliza Delphi.
}

unit ormbr.dml.generator.sqlite;

interface

uses
  SysUtils,
  Rtti,
  ormbr.dml.generator,
  ormbr.driver.register,
  ormbr.factory.interfaces,
  ormbr.mapping.classes,
  ormbr.mapping.explorer,
  ormbr.dml.commands,
  ormbr.criteria;

type
  /// <summary>
  /// Classe de conex�o concreta com dbExpress
  /// </summary>
  TDMLGeneratorSQLite = class(TDMLGeneratorAbstract)
  public
    constructor Create; override;
    destructor Destroy; override;
    function GeneratorSelectAll(AClass: TClass; APageSize: Integer; AID: Variant): string; override;
    function GeneratorSelectWhere(AClass: TClass; AWhere: string; AOrderBy: string; APageSize: Integer): string; override;
    function GeneratorSequenceCurrentValue(AObject: TObject; ACommandInsert: TDMLCommandInsert): Int64; override;
    function GeneratorSequenceNextValue(AObject: TObject; ACommandInsert: TDMLCommandInsert): Int64; override;
  end;

implementation

{ TDMLGeneratorSQLite }

constructor TDMLGeneratorSQLite.Create;
begin
  inherited;
  FDateFormat := 'yyyy-MM-dd';
  FTimeFormat := 'HH:MM:SS';
end;

destructor TDMLGeneratorSQLite.Destroy;
begin

  inherited;
end;

function TDMLGeneratorSQLite.GeneratorSelectAll(AClass: TClass; APageSize: Integer; AID: Variant): string;
var
  oCriteria: ICriteria;
begin
  oCriteria := GetCriteriaSelect(AClass, AID);
  if APageSize > -1 then
     Result := oCriteria.AsString + ' LIMIT %s OFFSET %s'
  else
     Result := oCriteria.AsString;
end;

function TDMLGeneratorSQLite.GeneratorSelectWhere(AClass: TClass;
  AWhere: string; AOrderBy: string; APageSize: Integer): string;
var
  oCriteria: ICriteria;
begin
  oCriteria := GetCriteriaSelect(AClass, -1);
  oCriteria.Where(AWhere);
  oCriteria.OrderBy(AOrderBy);
  if APageSize > -1 then
     Result := oCriteria.AsString + ' LIMIT %s OFFSET %s'
  else
     Result := oCriteria.AsString;
end;

function TDMLGeneratorSQLite.GeneratorSequenceCurrentValue(AObject: TObject;
  ACommandInsert: TDMLCommandInsert): Int64;
begin
  Result := ExecuteSequence(Format('SELECT SEQ AS SEQUENCE FROM SQLITE_SEQUENCE ' +
                                   'WHERE NAME = ''%s''', [ACommandInsert.Sequence.Name]));
end;

function TDMLGeneratorSQLite.GeneratorSequenceNextValue(AObject: TObject;
  ACommandInsert: TDMLCommandInsert): Int64;
begin
  FConnection.ExecuteDirect(Format('UPDATE SQLITE_SEQUENCE SET SEQ = SEQ + %s ' +
                                   'WHERE NAME = ''%s''', [IntToStr(ACommandInsert.Sequence.Increment), ACommandInsert.Sequence.Name]));
  Result := GeneratorSequenceCurrentValue(AObject, ACommandInsert);
end;

initialization
  TDriverRegister.RegisterDriver(dnSQLite, TDMLGeneratorSQLite.Create);

end.

