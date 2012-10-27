@import "RoundedBox.j"

@implementation AppController : CPObject
{
    @outlet RoundedBox  box;
    @outlet CPColorWell gradientStartColorWell;
    @outlet CPColorWell gradientEndColorWell;
    @outlet CPColorWell backgroundColorWell;
    @outlet CPColorWell borderColorWell;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(CPApplication)theApplication
{
    return YES;
}

- (@action)changeTitle:(id)sender
{
    var selection = [sender indexOfSelectedItem];
    if (selection == 0) { // Short title
        [box setTitle:@"Short Title"];
    } else { // Long title
        [box setTitle:@"A much longer title than is commonly encountered in boxes"];
    }
}


- (@action)changeTitlebar:(id)sender
{
    var fullTitles = ([sender state] == CPOnState);
    [box setDrawsFullTitleBar:fullTitles];
}


- (@action)changeSelected:(id)sender
{
    var selected = ([sender state] == CPOnState);
    [box setSelected:selected];
    [borderColorWell setEnabled:!selected];
}


- (@action)changeBackground:(id)sender
{
    if ([[sender selectedRadio] tag] == 0) {
        [box setDrawsGradientBackground:YES];
        [gradientStartColorWell setEnabled:YES];
        [gradientEndColorWell setEnabled:YES];
        [backgroundColorWell setEnabled:NO];
    } else {
        [box setDrawsGradientBackground:NO];
        [gradientStartColorWell setEnabled:NO];
        [gradientEndColorWell setEnabled:NO];
        [backgroundColorWell setEnabled:YES];
    }
}


- (@action)changeTitleColor:(id)sender
{
    [box setTitleColor:[sender color]];
}


- (@action)changeBorderColor:(id)sender
{
    [box setBorderColor:[sender color]];
}


- (@action)changeGradientStartColor:(id)sender
{
    [box setGradientStartColor:[sender color]];
}


- (@action)changeGradientEndColor:(id)sender
{
    [box setGradientEndColor:[sender color]];
}


- (@action)changeBackgroundColor:(id)sender
{
    [box setBackgroundColor:[sender color]];
}


@end

