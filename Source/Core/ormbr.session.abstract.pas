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

unit ormbr.session.abstract;

interface

uses
  DB,
  Rtti,
  TypInfo,
  Generics.Collections,
  ormbr.mapping.classes,
  ormbr.factory.interfaces,
  ormbr.mapping.explorerstrategy,
  ormbr.mapping.explorer;

type
  /// <summary>
  /// M - Sessão Abstract
  /// </summary>
  TSessionAbstract<M: class, constructor> = class abstract
  protected
    FPageSize: Integer;
    FModifiedFields: TDictionary<string, TList<string>>;
    FDeleteList: TObjectList<M>;
    FExplorer: IMappingExplorerStrategy;
    procedure Insert(const AObject: M); virtual; abstract;
    procedure Update(const AObject: M; const AKey: string); virtual; abstract;
    procedure Delete(const AObject: M); overload; virtual; abstract;
    procedure Delete(const AID: Integer); overload; virtual; abstract;
    procedure NextPacket(const AObjectList: TObjectList<M>); overload; virtual; abstract;
    procedure OpenID(const AID: Variant); virtual; abstract;
    procedure OpenSQL(const ASQL: string); virtual; abstract;
    procedure OpenWhere(const AWhere: string; const AOrderBy: string = ''); virtual; abstract;
    procedure RefreshRecord(const AColumnName: string); virtual; abstract;
    procedure NextPacket; overload; virtual; abstract;
    function Find: TObjectList<M>; overload; virtual; abstract;
    function Find(const AID: Integer): M; overload; virtual; abstract;
    function Find(const AID: string): M; overload; virtual; abstract;
    function FindSQL(const ASQL: String): TObjectList<M>; virtual; abstract;
    function FindWhere(const AWhere: string; const AOrderBy: string): TObjectList<M>; virtual; abstract;
    function ExistSequence: Boolean; virtual; abstract;
  public
    constructor Create(const APageSize: Integer = -1); overload; virtual;
    destructor Destroy; override;
    procedure ModifyFieldsCompare(const AKey: string; const AObjectSource, AObjectUpdate: TObject); virtual;
    function ModifiedFields: TDictionary<string, TList<string>>; virtual;
    function DeleteList: TObjectList<M>; virtual;
    function Explorer: IMappingExplorerStrategy;
  end;

implementation

uses
  ormbr.objects.helper,
  ormbr.rtti.helper,
  ormbr.types.blob,
  ormbr.mapping.attributes;

{ TSessionAbstract<M> }
constructor TSessionAbstract<M>.Create(const APageSize: Integer = -1);
begin
  FPageSize := APageSize;
  FModifiedFields := TObjectDictionary<string, TList<string>>.Create([doOwnsValues]);
  FDeleteList := TObjectList<M>.Create;
  FExplorer := TMappingExplorer.GetInstance;
  /// <summary>
  /// Inicia uma lista interna para gerenciar campos alterados
  /// </summary>
  FModifiedFields.Clear;
  FModifiedFields.Add(M.ClassName, TList<string>.Create);
end;

destructor TSessionAbstract<M>.Destroy;
begin
  FExplorer := nil;
  FDeleteList.Clear;
  FDeleteList.Free;
  FModifiedFields.Clear;
  FModifiedFields.Free;
  inherited;
end;

function TSessionAbstract<M>.ModifiedFields: TDictionary<string, TList<string>>;
begin
  Result := FModifiedFields;
end;

function TSessionAbstract<M>.DeleteList: TObjectList<M>;
begin
  Result := FDeleteList;
end;

function TSessionAbstract<M>.Explorer: IMappingExplorerStrategy;
begin
  Result := FExplorer;
end;

procedure TSessionAbstract<M>.ModifyFieldsCompare(const AKey: string;
  const AObjectSource, AObjectUpdate: TObject);
const
  cPropertyTypes = [tkUnknown,
                    tkInterface,
                    tkClass,
                    tkClassRef,
                    tkPointer,
                    tkProcedure];
var
  LRttiType: TRttiType;
  LProperty: TRttiProperty;
  LColumn: TCustomAttribute;
begin
  AObjectSource.GetType(LRttiType);
  try
    for LProperty in LRttiType.GetProperties do
    begin
      if LProperty.IsNoUpdate then
        Continue;
      /// <summary>
      /// Validação para entrar no IF somente propriedades que o tipo nao esteja na lista
      /// </summary>
      if not (LProperty.PropertyType.TypeKind in cPropertyTypes) then
      begin
        if not FModifiedFields.ContainsKey(AKey) then
          FModifiedFields.Add(AKey, TList<string>.Create);
        /// <summary>
        /// Se o tipo da property for tkRecord provavelmente tem Nullable nela
        /// Se não for tkRecord entra no ELSE e pega o valor de forma direta
        /// </summary>
        if LProperty.PropertyType.TypeKind = tkRecord then // Nullable, Proxy ou TBlob
        begin
          if LProperty.IsBlob then
          begin
            if LProperty.GetValue(AObjectSource).AsType<TBlob>.ToSize <>
               LProperty.GetValue(AObjectUpdate).AsType<TBlob>.ToSize then
            begin
              LColumn := LProperty.GetColumn;
              if LColumn <> nil then
                FModifiedFields.Items[AKey].Add(Column(LColumn).ColumnName);
            end;
          end
          else
          begin
            if LProperty.GetNullableValue(AObjectSource).AsType<Variant> <>
               LProperty.GetNullableValue(AObjectUpdate).AsType<Variant> then
            begin
              LColumn := LProperty.GetColumn;
              if LColumn <> nil then
                FModifiedFields.Items[AKey].Add(Column(LColumn).ColumnName);
            end;
          end;
        end
        else
        begin
          if LProperty.GetValue(AObjectSource).AsType<Variant> <>
             LProperty.GetValue(AObjectUpdate).AsType<Variant> then
          begin
            LColumn := LProperty.GetColumn;
            if LColumn <> nil then
              FModifiedFields.Items[AKey].Add(Column(LColumn).ColumnName);
          end;
        end;
      end;
    end;
  except
    raise;
  end;
end;

end.
