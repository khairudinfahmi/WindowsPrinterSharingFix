@{
    # Exclude non-relevant style rules for standalone interactive CLI repair scripts
    ExcludeRules = @(
        'PSUseApprovedVerbs',
        'PSAvoidUsingWriteHost',
        'PSUseShouldProcessForStateChangingFunctions',
        'PSUseSingularNouns',
        'PSAvoidUsingEmptyCatchBlock',
        'PSUseBOMForUnicodeEncodedFile',
        'PSAvoidTrailingWhitespace'
    )
}
