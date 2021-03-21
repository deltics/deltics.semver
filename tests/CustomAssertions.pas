
{$i deltics.smoketest.inc}

  unit CustomAssertions;


interface

  uses
    Deltics.SemVer,
    Deltics.Smoketest.Assertions,
    Deltics.Smoketest.Assertions.Factory,
    Deltics.Smoketest.Test;


  type
    SemVerAssertions = interface
    ['{BAC03E49-08C6-4EF3-9244-3DAB36DD188F}']
      function Equals(aMajorVersion, aMinorVersion, aPatch: Integer): AssertionResult;
      function IsNewerThan(aValue: ISemVer): AssertionResult;
    end;


    SemVerAssertFactory = interface(AssertFactory)
    ['{5AA21A42-B13C-445A-88B7-117406279E98}']
      function Assert(const aValue: ISemVer): SemVerAssertions; overload;
    end;


    TSemVerAssertFactory = class(TAssertFactory, SemVerAssertFactory)
    public
      function Assert(const aValue: ISemVer): SemVerAssertions; overload;
    end;


    TSemVerAssertions = class(TAssertions, SemVerAssertions)
    private
      fValue: ISemVer;
      function Equals(aMajorVersion, aMinorVersion, aPatch: Integer): AssertionResult; reintroduce;
      function IsNewerThan(aValue: ISemVer): AssertionResult;
    public
      constructor Create(const aValueName: String; const aValue: ISemVer);
      property Value: ISemVer read fValue;
    end;


    TTest = class(Deltics.Smoketest.Test.TTest)
    protected
      function Test(const aValueName: String): SemVerAssertFactory; reintroduce; overload;
      function Test(const aValueName: String; aValueNameArgs: array of const): SemVerAssertFactory; reintroduce; overload;
    end;



implementation


{ TSemVerAssertions }

  constructor TSemVerAssertions.Create(const aValueName: String;
                                       const aValue: ISemVer);
  begin
    inherited Create(aValueName, aValue.AsString);

    fValue := aValue;
  end;


  function TSemVerAssertions.Equals(aMajorVersion, aMinorVersion, aPatch: Integer): AssertionResult;
  begin
    Description := Format('{valueName} parsed as %d.%d.%d', [aMajorVersion, aMinorVersion, aPatch]);
    Failure     := Format('{valueName} parsed as {value} instead of %d.%d.%d',
                          [aMajorVersion, aMinorVersion, aPatch]);

    result := Assert((Value.MajorVersion = aMajorVersion)
                 and (Value.MinorVersion = aMinorVersion)
                 and (Value.Patch = aPatch));
  end;



  function TSemVerAssertions.IsNewerThan(aValue: ISemVer): AssertionResult;
  begin
    Description := Format('({value}).IsNewerThan({older})', [aValue.AsString]);
    Failure     := Format('({value}).IsNewerThan({older}) is FALSE', [aValue.AsString]);

    result := Assert(TSemVer.Compare(Value, aValue) = 1);
  end;



{ TSemVerAssertFactory }

  function TSemVerAssertFactory.Assert(const aValue: ISemVer): SemVerAssertions;
  begin
    result := TSemVerAssertions.Create(ValueName, aValue);
  end;



{ TTest }

  function TTest.Test(const aValueName: String): SemVerAssertFactory;
  begin
    result := inherited Test(aValueName) as SemVerAssertFactory;
  end;


  function TTest.Test(const aValueName: String;
                            aValueNameArgs: array of const): SemVerAssertFactory;
  begin
    result := inherited Test(aValueName, aValueNameArgs) as SemVerAssertFactory;
  end;




initialization
  TSemVerAssertFactory.Register(SemVerAssertFactory);
end.
