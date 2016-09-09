#if 0

/**
 * @brief This will build the input accessory for the keyboard/textfield, and
 * given textFieldIndx it will enable/disable prev|next.
 */
- (UIToolbar *)buildAccessory:(int)textFieldIndx
{
    UIToolbar *keyboardAccessories = [[UIToolbar alloc] init];
    [keyboardAccessories setBarStyle:UIBarStyleBlackTranslucent];
    [keyboardAccessories sizeToFit];
    keyboardAccessories.autoresizingMask |= UIViewAutoresizingFlexibleHeight;
    
    UIBarButtonItem *flexibleSpace = \
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                      target:nil
                                                      action:nil];
    
    UIBarButtonItem *cancelKeyBtn = \
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                      target:self
                                                      action:@selector(doneKeyHandler)];
    
    UIBarButtonItem *prevKeyBtn = \
        [[UIBarButtonItem alloc] initWithTitle:@"Prev"
                                         style:UIBarButtonItemStyleBordered
                                        target:self
                                        action:@selector(prevKeyHandler)];
    
    UIBarButtonItem *nextKeyBtn = \
        [[UIBarButtonItem alloc] initWithTitle:@"Next"
                                         style:UIBarButtonItemStyleBordered
                                        target:self
                                        action:@selector(nextKeyHandler)];

    /* 
     * Could store the textfields in an array and do a neato check, but who
     * cares.
     */
    switch (textFieldIndx)
    {
        case 0:
            [prevKeyBtn setEnabled:NO];
            break;
        case 2:
            [nextKeyBtn setEnabled:NO];
            break;
        default:
            break;
    }
    
    [keyboardAccessories setItems:@[prevKeyBtn, nextKeyBtn, flexibleSpace, cancelKeyBtn]
                         animated:YES];
    
    return keyboardAccessories;
}

#endif
