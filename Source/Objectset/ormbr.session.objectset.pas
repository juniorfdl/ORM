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

unit ormbr.session.objectset;

interface

uses
  DB,
  Rtti,
  TypInfo,
  Classes,
  Variants,
  SysUtils,
  Generics.Collections,
  /// orm
  ormbr.objects.manager,
  ormbr.objects.manager.abstract,
  ormbr.mapping.explorerstrategy,
  ormbr.session.abstract,
  ormbr.factory.interfaces;

type
  /// <summary>
  /// M - Sessão Abstract
  /// </summary>
  TSessionObjectSet<M: class, constructor> = class(TSessionAbstract<M>)
  private
  protected
    FManager: TObjectManagerAbstract<M>;
    FConnection: IDBConnection;
  public
    constructor Create(const AConnection: IDBConnection; const APageSize: Integer = -1); overload;
    destructor Destroy; override;
    procedure Insert(const AObject: M); override;
    procedure Update(const AObject: M; const AKey: string); override;
    procedure Delete(const AObject: M); override;
    procedure ModifyFieldsCompare(const AKey: string; const AObjectSource, AObjectUpdate: TObject); override;
    procedure NextPacket(const AObjectList: TObjectList<M>); overload; override;
    procedure OpenID(const AID: Variant); override;
    procedure OpenSQL(const ASQL: string); override;
    procedure OpenWhere(const AWhere: string; const AOrderBy: string = ''); override;
    procedure RefreshRecord(const AColumnName: string); override;
    function Find: TObjectList<M>; overload; override;
    function Find(const AID: Integer): M; overload; override;
    function FindSQL(const ASQL: String): TObjectList<M>; override;
    function FindWhere(const AWhere: string; const AOrderBy: string): TObjectList<M>; overload; override;
    function ExistSequence: Boolean; override;
    function ModifiedFields: TDictionary<string, TList<string>>; override;
    function DeleteList: TObjectList<M>; override;
    function Explorer: IMappingExplorerStrategy;
//    function Manager: TObjectManagerAbstract<M>;
  end;

implementation

{ TSessionObjectSet<M> }

constructor TSessionObjectSet<M>.Create(const AConnection: IDBConnection; const APageSize: Integer);
begin
  inherited Create(APageSize);
  FConnection := AConnection;
  FManager := TObjectManager<M>.Create(Self, AConnection, APageSize);
end;

procedure TSessionObjectSet<M>.Insert(const AObject: M);
begin
  inherited;
  FManager.InsertInternal(AObject);
end;

procedure TSessionObjectSet<M>.Delete(const AObject: M);
begin
  inherited;
  FManager.DeleteInternal(AObject);
end;

destructor TSessionObjectSet<M>.Destroy;
begin
  FManager.Free;
  inherited;
end;

function TSessionObjectSet<M>.ExistSequence: Boolean;
begin
  inherited;
  Result := FManager.ExistSequence;
end;

//function TSessionObjectSet<M>.Manager: TObjectManagerAbstract<M>;
//begin
//  Result := FManager;
//end;

procedure TSessionObjectSet<M>.Update(const AObject: M; const AKey: string);
begin
  inherited;
  FManager.UpdateInternal(AObject, FModifiedFields.Items[AKey]);
end;

function TSessionObjectSet<M>.Find: TObjectList<M>;
begin
  inherited;
  Result := FManager.Find;
end;

function TSessionObjectSet<M>.Find(const AID: Integer): M;
begin
  inherited;
  Result := FManager.Find(AID);
end;

function TSessionObjectSet<M>.FindSQL(const ASQL: String): TObjectList<M>;
begin
  inherited;
end;

function TSessionObjectSet<M>.FindWhere(const AWhere: string;
  const AOrderBy: string): TObjectList<M>;
begin
  inherited;
  Result := FManager.FindWhere(AWhere, AOrderBy);
end;

procedure TSessionObjectSet<M>.NextPacket(const AObjectList: TObjectList<M>);
begin
  inherited;
  if not FManager.FetchingRecords then
    FManager.NextPacketList(AObjectList);
end;

procedure TSessionObjectSet<M>.OpenID(const AID: Variant);
begin
  inherited;
end;

procedure TSessionObjectSet<M>.OpenSQL(const ASQL: string);
begin
  inherited;
end;

procedure TSessionObjectSet<M>.OpenWhere(const AWhere, AOrderBy: string);
begin
  inherited;
end;

procedure TSessionObjectSet<M>.RefreshRecord(const AColumnName: string);
begin
  inherited;
end;

procedure TSessionObjectSet<M>.ModifyFieldsCompare(const AKey: string;
  const AObjectSource, AObjectUpdate: TObject);
begin
  inherited ModifyFieldsCompare(AKey, AObjectSource, AObjectUpdate);
end;

function TSessionObjectSet<M>.ModifiedFields: TDictionary<string, TList<string>>;
begin
  Result := inherited ModifiedFields;
end;

function TSessionObjectSet<M>.DeleteList: TObjectList<M>;
begin
  Result := inherited DeleteList;
end;

function TSessionObjectSet<M>.Explorer: IMappingExplorerStrategy;
begin
  Result := inherited Explorer;
end;

end.
