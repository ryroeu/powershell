@{
    Severity     = @('Error', 'Warning')
    ExcludeRules = @(
        # Interactive administration scripts intentionally use host-only status and prompts.
        'PSAvoidUsingWriteHost'

        # PowerShell 7 defaults to UTF-8 without a BOM; requiring a BOM is a Windows PowerShell convention.
        'PSUseBOMForUnicodeEncodedFile'
    )
}
