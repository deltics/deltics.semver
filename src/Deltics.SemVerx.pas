
{$i deltics.semver.inc}

  unit Deltics.SemVer;


interface

  uses
    SysUtils,
    Deltics.InterfacedObjects,
    Deltics.StringLists;


  type
    TSemVer = class;
    TSemVerReference = class;
    TIdentifierList = class;


    TIdentifierType = (itInteger, itString);


    ISemVer = interface
    ['{FD69E6C7-19BD-4528-B5CF-9F371A4398D6}']
      function get_AsString: String;
      function get_MajorVersion: Integer;
      function get_MinorVersion: Integer;
      function get_Patch: Integer;
      function get_Identifiers: TIdentifierList;
      function get_IsPreRelease: Boolean;
      function get_MetaData: TIdentifierList;
      procedure set_AsString(const aValue: String);
      function IsCompatibleWith(const aReference: String): Boolean; overload;
      function IsCompatibleWith(const aReference: ISemVer): Boolean; overload;
      function IsCompatibleWith(const aReference: TSemVerReference): Boolean; overload;
      function IsNewerThan(const aVersion: String): Boolean; overload;
      function IsNewerThan(const aVersion: ISemVer): Boolean; overload;
      property AsString: String read get_AsString write set_AsString;
      property MajorVersion: Integer read get_MajorVersion;
      property MinorVersion: Integer read get_MinorVersion;
      property Patch: Integer read get_Patch;
      property Identifiers: TIdentifierList read get_Identifiers;
      property IsPreRelease: Boolean read get_IsPreRelease;
      property MetaData: TIdentifierList read get_Metadata;
      property Version: String read get_AsString write set_AsString;
    end;


    TSemVer = class(TComInterfacedObject, ISemVer)
    public
      class function Compare(const a, b: ISemVer): Integer; overload;
      class function Compare(const a, b: String): Integer; overload;
    private
      fMajorVersion: Integer;
      fMinorVersion: Integer;
      fPatch: Integer;
      fIdentifiers: TIdentifierList;
      fMetadata: TIdentifierList;
      function get_AsString: String;
      function get_MajorVersion: Integer;
      function get_MinorVersion: Integer;
      function get_Patch: Integer;
      function get_Identifiers: TIdentifierList;
      function get_IsPreRelease: Boolean;
      function get_MetaData: TIdentifierList;
      procedure set_AsString(const aValue: String);
    public
      constructor Create(const aVersion: String = '');
      destructor Destroy; override;
      function IsCompatibleWith(const aReference: String): Boolean; overload;
      function IsCompatibleWith(const aVersion: ISemVer): Boolean; overload;
      function IsCompatibleWith(const aReference: TSemVerReference): Boolean; overload;
      function IsNewerThan(const aVersion: String): Boolean; overload;
      function IsNewerThan(const aVersion: ISemVer): Boolean; overload;
      property AsString: String read get_AsString write set_AsString;
      property MajorVersion: Integer read fMajorVersion;
      property MinorVersion: Integer read fMinorVersion;
      property Patch: Integer read fPatch;
      property Identifiers: TIdentifierList read fIdentifiers;
      property MetaData: TIdentifierList read fMetadata;
    end;


    TSemVerReference = class
    {
      Yes, identical to a SemVer but allows ANY_VERSION in each of the
       major, minor and patch fields.  i.e. a "wildcard" semver.
    }
    public
      class function Compare(const a, b: TSemVerReference): Integer;
    private
      fMajorVersion: Integer;
      fMinorVersion: Integer;
      fPatch: Integer;
      fIdentifiers: TIdentifierList;
      fMetadata: TIdentifierList;
      function get_AsString: String;
    public
      constructor Create(const aVersion: String);
      destructor Destroy; override;
      function IsCompatibleWith(const aReference: String): Boolean; overload;
      function IsCompatibleWith(const aReference: TSemVerReference): Boolean; overload;
      property AsString: String read get_AsString;
      property MajorVersion: Integer read fMajorVersion;
      property MinorVersion: Integer read fMinorVersion;
      property Patch: Integer read fPatch;
      property Identifiers: TIdentifierList read fIdentifiers;
      property MetaData: TIdentifierList read fMetadata;
    end;


    TIdentifierList = class
    private
      fItems: TStringList;
      function get_AsString: String;
      function get_Count: Integer;
      function get_IdentifierAsInteger(const aIndex: Integer): Integer;
      function get_IdentifierAsString(const aIndex: Integer): String;
      function get_IdentifierType(const aIndex: Integer): TIdentifierType;
    public
      constructor Create(const aString: String);
      destructor Destroy; override;
      property AsString: String read get_AsString;
      property Count: Integer read get_Count;
      property IdentifierAsInteger[const aIndex: Integer]: Integer read get_IdentifierAsInteger;
      property IdentifierAsString[const aIndex: Integer]: String read get_IdentifierAsString; default;
      property IdentifierType[const aIndex: Integer]: TIdentifierType read get_IdentifierType;
    end;


    function CompareSemVerStrings(const aSemVer, aOtherSemVer: String): Integer;


implementation

  uses
    Math,
    Deltics.Exceptions,
    Deltics.StringParsers,
    Deltics.Strings,
    Deltics.StringTemplates;


  const
    ERROR       = -1;
    ANY_VERSION = MaxInt;


  function CompareSemVerStrings(const aSemVer, aOtherSemVer: String): Integer; {$ifdef InlineMethods} inline; {$endif}
  begin
    result := TSemVer.Compare(aSemVer, aOtherSemVer);
  end;



{ TSemVer }

  class function TSemVer.Compare(const a, b: ISemVer): Integer;
  const
    ArgA      = 1;
    ArgB      = -1;
    ArgsEqual = 0;
  var
    i: Integer;
    identsA, identsB: StringArray;
    identA, identB: String;
    isIntA, isIntB: Boolean;
    intA, intB: Integer;
  begin
    result := ArgsEqual;

    if a.MajorVersion > b.MajorVersion then
      result := ArgA
    else if a.MajorVersion < b.MajorVersion then
      result := ArgB
    else
    begin
      if a.MinorVersion > b.MinorVersion then
        result := ArgA
      else if a.MinorVersion < b.MinorVersion then
        result := ArgB
      else
      begin
        if a.Patch > b.Patch then
          result := ArgA
        else if a.Patch < b.Patch then
          result := ArgB
        else
        begin
          STR.Split(STR.Lowercase(a.Identifiers.AsString), '.', identsA);
          STR.Split(STR.Lowercase(b.Identifiers.AsString), '.', identsB);

          for i := 0 to Min(High(identsA), High(identsB)) do
          begin
            identA := identsA[i];
            identB := identsB[i];

            isIntA := Parse(identA).IsInteger(intA);
            isIntB := Parse(identB).IsInteger(intB);

            if isIntA and isIntB then
             result := Sign(intA - intB)
            else if isIntB then
             result := ArgA
            else if isIntA then
             result := ArgB
            else if identA > identB then
              result := ArgA
            else if identA < identB then
              result := ArgB;

            if result <> 0 then
              BREAK;
          end;

          if (result = 0) then
            result := Sign(High(identsB) - High(identsA));
        end;
      end;
    end;
  end;



  class function TSemVer.Compare(const a, b: String): Integer;
  var
    sa, sb: TSemVer;
  begin
    sa := NIL;
    sb := NIL;
    try
      sa := TSemVer.Create(a);
      sb := TSemVer.Create(b);

      result := Compare(sa, sb);

    finally
      sa.Free;
      sb.Free;
    end;
  end;


  constructor TSemVer.Create(const aVersion: String);
  begin
    inherited Create;

    AsString := aVersion;
  end;



  destructor TSemVer.Destroy;
  begin
    fMetadata.Free;
    fIdentifiers.Free;

    inherited;
  end;


  function TSemVer.get_AsString: String;
  begin
    result := Format('%d.%d.%d', [fMajorVersion, fMinorVersion, fPatch]);

    if fIdentifiers.Count > 0 then
      result := result + '-' + fIdentifiers.AsString;

    if fMetadata.Count > 0 then
      result := result + '+' + fMetaData.AsString;
  end;


  function TSemVer.get_Identifiers: TIdentifierList;
  begin
    result := fIdentifiers;
  end;


  function TSemVer.get_IsPreRelease: Boolean;
  begin
    result := (fIdentifiers.Count > 0);
  end;


  function TSemVer.get_MajorVersion: Integer;
  begin
    result := fMajorVersion;
  end;


  function TSemVer.get_MetaData: TIdentifierList;
  begin
    result := fMetaData;
  end;


  function TSemVer.get_MinorVersion: Integer;
  begin
    result := fMinorVersion;
  end;


  function TSemVer.get_Patch: Integer;
  begin
    result := fPatch;
  end;


  procedure TSemVer.set_AsString(const aValue: String);
  const
    TEMPLATE_Version                    = '[major:int].[minor:int].[patch:int]';
    TEMPLATE_VersionIdentifiers         = TEMPLATE_Version + '-[identifiers]';
    TEMPLATE_VersionMetadata            = TEMPLATE_Version + '+[metadata]';
    TEMPLATE_VersionIdentifiersMetadata = TEMPLATE_Version + '-[identifiers]+[metadata]';
  var
    vars: TStringList;
    ident: String;
    meta: String;
  begin
    if (aValue = '') then
    begin
      fMajorVersion := 0;
      fMinorVersion := 0;
      fPatch        := 0;

      if Assigned(fIdentifiers) then fIdentifiers.fItems.Clear;
      if Assigned(fMetadata) then fMetaData.fItems.Clear;

      EXIT;
    end;

    vars := TStringList.Create;
    try
      if NOT TStringTemplate.Match([TEMPLATE_VersionIdentifiersMetadata,
                                    TEMPLATE_VersionIdentifiers,
                                    TEMPLATE_VersionMetadata,
                                    TEMPLATE_Version], aValue, vars) then
        raise EArgumentException.CreateFmt('''%s'' is not a valid SemVer version string', [aValue]);

      fMajorVersion := Parse(vars.Values['major']).AsInteger;
      fMinorVersion := Parse(vars.Values['minor']).AsInteger;
      fPatch        := Parse(vars.Values['patch']).AsInteger;

      if vars.ContainsName('identifiers') then
        ident := vars.Values['identifiers'];

      if vars.ContainsName('metadata') then
        meta := vars.Values['metadata'];

    finally
      vars.Free;
    end;

    fIdentifiers.Free;
    fMetadata.Free;

    fIdentifiers := TIdentifierList.Create(ident);
    fMetadata    := TIdentifierList.Create(meta);
  end;


  function TSemVer.IsCompatibleWith(const aReference: String): Boolean;
  var
    ref: TSemVerReference;
  begin
    ref := TSemVerReference.Create(aReference);
    try
      result := IsCompatibleWith(ref);

    finally
      ref.Free;
    end;
  end;



  function TSemVer.IsCompatibleWith(const aReference: TSemVerReference): Boolean;
  begin
    result := (MajorVersion = aReference.MajorVersion)
           or (aReference.MajorVersion = ANY_VERSION);
    if NOT result then
      EXIT;

    result := (MinorVersion >= aReference.MinorVersion)
           or (aReference.MinorVersion = ANY_VERSION);
    if NOT result then
      EXIT;

    result := (MinorVersion > aReference.MinorVersion)
           or (Patch >= aReference.Patch)
           or (aReference.Patch = ANY_VERSION);
    if NOT result then
      EXIT;
  end;



  function TSemVer.IsCompatibleWith(const aVersion: ISemVer): Boolean;
  begin
    result := (MajorVersion = aVersion.MajorVersion);
  end;



  function TSemVer.IsNewerThan(const aVersion: String): Boolean;
  var
    other: TSemVer;
  begin
    other := TSemVer.Create(aVersion);
    try
      result := IsNewerThan(other);
    finally
      other.Free;
    end;
  end;


  function TSemVer.IsNewerThan(const aVersion: ISemVer): Boolean;
  begin
    result := (Compare(self, aVersion) = 1);
  end;





{ TIdentifierList }

  constructor TIdentifierList.Create(const aString: String);
  var
    i: Integer;
    idents: StringArray;
  begin
    inherited Create;

    fItems := TStringList.Create;

    if STR.IsEmpty(aString) then
      EXIT;

    STR.Split(aString, '.', idents);

    for i := Low(idents) to High(idents) do
      fItems.Add(idents[i]);
  end;



  destructor TIdentifierList.Destroy;
  begin
    fItems.Free;

    inherited;
  end;



  function TIdentifierList.get_AsString: String;
  var
    i: Integer;
  begin
    result := '';

    if fItems.Count = 0 then
      EXIT;

    for i := 0 to Pred(fItems.Count) do
      result := result + fItems[i] + '.';

    SetLength(result, Length(result) - 1);
  end;



  function TIdentifierList.get_Count: Integer;
  begin
    result := fItems.Count;
  end;



  function TIdentifierList.get_IdentifierAsInteger(const aIndex: Integer): Integer;
  begin
    result := StrToInt(IdentifierAsString[aIndex]);
  end;



  function TIdentifierList.get_IdentifierAsString(const aIndex: Integer): String;
  begin
    result := fItems[aIndex];
  end;



  function TIdentifierList.get_IdentifierType(const aIndex: Integer): TIdentifierType;
  begin
    if Parse(fItems[aIndex]).IsInteger then
      result := itInteger
    else
      result := itString;
  end;




{ TSemVerReference }

  class function TSemVerReference.Compare(const a, b: TSemVerReference): Integer;
  var
    identsA, identsB: String;
    metaA, metaB: String;
  begin
    if (a.MajorVersion < b.MajorVersion) then
      result := -1
    else if a.MajorVersion > b.MajorVersion then
      result := 1
    else
    begin
      if a.MinorVersion < b.MinorVersion then
        result := -1
      else if a.MinorVersion > b.MinorVersion then
        result := 1
      else
      begin
       if a.Patch < b.Patch then
         result := -1
       else if a.Patch > b.Patch then
         result := 1
       else
       begin
         identsA := STR.Lowercase(a.Identifiers.AsString);
         identsB := STR.Lowercase(b.Identifiers.AsString);

         metaA := STR.Lowercase(a.MetaData.AsString);
         metaB := STR.Lowercase(b.MetaData.AsString);

         if identsA < identsB then
           result := -1
         else if identsA > identsB then
           result := 1
         else
         begin
           if metaA < metaB then
             result := -1
           else if metaA > metaB then
             result := 1
           else
             result := 0;
         end;
       end;
      end;
    end;
  end;



  constructor TSemVerReference.Create(const aVersion: String);
  const
    TEMPLATE_Version                    = '[major].[minor].[patch]';
    TEMPLATE_VersionIdentifiers         = TEMPLATE_Version + '-[identifiers]';
    TEMPLATE_VersionMetadata            = TEMPLATE_Version + '+[metadata]';
    TEMPLATE_VersionIdentifiersMetadata = TEMPLATE_Version + '-[identifiers]+[metadata]';
  var
    vars: TStringList;
    major: String;
    minor: String;
    patch: String;
    ident: String;
    meta: String;

  begin
    inherited Create;

    ident := '';
    meta  := '';

    vars := TStringList.Create;
    try
      if NOT TStringTemplate.Match([TEMPLATE_VersionIdentifiersMetadata,
                                    TEMPLATE_VersionIdentifiers,
                                    TEMPLATE_VersionMetadata,
                                    TEMPLATE_Version], aVersion, vars) then
        raise EArgumentException.CreateFmt('''%s'' is not a valid version string', [aVersion]);

      major := vars.Values['major'];
      minor := vars.Values['minor'];
      patch := vars.Values['patch'];

      if major = '*' then fMajorVersion := ANY_VERSION else fMajorVersion := Parse(major).AsIntegerOrDefault(ERROR);
      if minor = '*' then fMinorVersion := ANY_VERSION else fMinorVersion := Parse(minor).AsIntegerOrDefault(ERROR);
      if patch = '*' then fPatch        := ANY_VERSION else fPatch        := Parse(patch).AsIntegerOrDefault(ERROR);

      if (fMajorVersion = ERROR) or (fMinorVersion = ERROR) or (fPatch = ERROR) then
        raise Exception.CreateFmt('''%s'' is not a valid SemVer reference', [aVersion]);

      if vars.ContainsName('identifiers') then
        ident := vars.Values['identifiers'];

      if vars.ContainsName('metadata') then
        meta := vars.Values['metadata'];

    finally
      vars.Free;
    end;

    fIdentifiers := TIdentifierList.Create(ident);
    fMetadata    := TIdentifierList.Create(meta);
  end;



  destructor TSemVerReference.Destroy;
  begin
    fMetadata.Free;
    fIdentifiers.Free;

    inherited;
  end;



  function TSemVerReference.get_AsString: String;
  begin
  result := Format('%d.%d.%d', [fMajorVersion, fMinorVersion, fPatch]);

    if fIdentifiers.Count > 0 then
      result := result + '-' + fIdentifiers.AsString;

    if fMetadata.Count > 0 then
      result := result + '+' + fMetaData.AsString;
    end;



  function TSemVerReference.IsCompatibleWith(const aReference: String): Boolean;
  var
    ref: TSemVerReference;
  begin
    ref := TSemVerReference.Create(aReference);
    try
      result := IsCompatibleWith(ref);

    finally
      ref.Free;
    end;
  end;



  function TSemVerReference.IsCompatibleWith(const aReference: TSemVerReference): Boolean;
  begin
    result := (MajorVersion = aReference.MajorVersion) or (aReference.MajorVersion = ANY_VERSION);
    if NOT result then
      EXIT;

    result := (MinorVersion >= aReference.MinorVersion) or (aReference.MinorVersion = ANY_VERSION);
    if NOT result then
      EXIT;

    result := (Patch >= aReference.MinorVersion) or (aReference.Patch = ANY_VERSION);
    if NOT result then
      EXIT;
  end;

end.
