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

unit ormbr.types.lazy;

interface

uses
  SysUtils,
  TypInfo;

const
  ObjCastGUID: TGUID = '{CEDF24DE-80A4-447D-8C75-EB871DC121FD}';

type
  ILazy<T: class> = interface(TFunc<T>)
    ['{D2646FB7-724B-44E4-AFCB-1FDD991DACB3}']
    function IsValueCreated: Boolean;
    property Value: T read Invoke;
  end;

  TLazy<T: class> = class(TInterfacedObject, ILazy<T>, IInterface)
  private
    FIsValueCreated: Boolean;
    FValue: T;
    FValueFactory: TFunc<T>;
    procedure Initialize;
    function Invoke: T;
  protected
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
  public
    constructor Create(ValueFactory: TFunc<T>);
    destructor Destroy; override;

    function IsValueCreated: Boolean;
    property Value: T read Invoke;
  end;

  Lazy<T: class> = record
  strict private
    FLazy: ILazy<T>;
    function GetValue: T;
  public
    class constructor Create;
    property Value: T read GetValue;
    class operator Implicit(const Value: Lazy<T>): ILazy<T>; overload;
    class operator Implicit(const Value: Lazy<T>): T; overload;
    class operator Implicit(const Value: TFunc<T>): Lazy<T>; overload;
  end;

implementation

uses
  ormbr.mapping.rttiutils;

{ TLazy<T> }

constructor TLazy<T>.Create(ValueFactory: TFunc<T>);
begin
  FValueFactory := ValueFactory;
end;

destructor TLazy<T>.Destroy;
begin
  if FIsValueCreated then
  begin
    if Assigned(FValue) then
       FValue.Free;
  end;
  inherited;
end;

procedure TLazy<T>.Initialize;
begin
  if not FIsValueCreated then
  begin
    FValue := FValueFactory();
    FIsValueCreated := True;
  end;
end;

function TLazy<T>.Invoke: T;
begin
  Initialize();
  Result := FValue;
end;

function TLazy<T>.IsValueCreated: Boolean;
begin
  Result := FIsValueCreated;
end;

function TLazy<T>.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if IsEqualGUID(IID, ObjCastGUID) then
  begin
    Initialize;
  end;
  Result := inherited;
end;

{ Lazy<T> }

class constructor Lazy<T>.Create;
begin
  TRttiSingleton.GetInstance.GetRttiType(TypeInfo(T));
end;

function Lazy<T>.GetValue: T;
begin
  Result := FLazy();
end;

class operator Lazy<T>.Implicit(const Value: Lazy<T>): ILazy<T>;
begin
  Result := Value.FLazy;
end;

class operator Lazy<T>.Implicit(const Value: Lazy<T>): T;
begin
  Result := Value.Value;
end;

class operator Lazy<T>.Implicit(const Value: TFunc<T>): Lazy<T>;
begin
  Result.FLazy := TLazy<T>.Create(Value);
end;

end.

