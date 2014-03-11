/*
=================================================
CEPrintView
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2005.10.01

-------------------------------------------------

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA. 


=================================================
*/

#import "CEPrintView.h"
#import "constants.h"


typedef NS_ENUM(NSUInteger, CEAlignmentType) {
    CEAlignLeft,
    CEAlignCenter,
    CEAlignRight
};


@interface CEPrintView ()

@property (nonatomic, retain) NSAttributedString *headerOneString;
@property (nonatomic, retain) NSAttributedString *headerTwoString;
@property (nonatomic, retain) NSAttributedString *footerOneString;
@property (nonatomic, retain) NSAttributedString *footerTwoString;
@property (nonatomic, assign) CEAlignmentType headerOneAlignment;
@property (nonatomic, assign) CEAlignmentType headerTwoAlignment;
@property (nonatomic, assign) CEAlignmentType footerOneAlignment;
@property (nonatomic, assign) CEAlignmentType footerTwoAlignment;
@property (nonatomic, assign) BOOL printsHeader;
@property (nonatomic, assign) BOOL printsFooter;
@property (nonatomic, assign) BOOL printsHeaderSeparator;
@property (nonatomic, assign) BOOL printsFooterSeparator;
@property (nonatomic, assign) BOOL readyToPrint;
@property (nonatomic, assign) BOOL printsLineNum;
@property (nonatomic, assign) BOOL readyToDrawPageNum;
@property (nonatomic, assign) CGFloat xOffset;
@property (nonatomic, retain) NSDictionary *headerFooterAttrs;
@property (nonatomic, retain) NSDictionary *lineNumAttrs;

@end


//------------------------------------------------------------------------------------------

#pragma mark -



@implementation CEPrintView

#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
- (id)initWithFrame:(NSRect)frame
// 初期化
// ------------------------------------------------------
{
    self = [super initWithFrame:frame];

    if (self) {
        [self setFilePath:nil];
        [self setLineNumAttrs:nil];
        [self setHeaderFooterAttrs:nil];
        [self setPrintValues:nil];
        [self setHeaderOneString:nil];
        [self setHeaderTwoString:nil];
        [self setFooterOneString:nil];
        [self setFooterTwoString:nil];
        [self setHeaderOneAlignment:CEAlignLeft];
        [self setHeaderTwoAlignment:CEAlignLeft];
        [self setFooterOneAlignment:CEAlignLeft];
        [self setFooterTwoAlignment:CEAlignLeft];
        [self setXOffset:0.0];
        [self setReadyToPrint:NO];  // =ヘッダ／フッタ生成処理などの準備完了フラグ
        [self setPrintsLineNum:NO];
        [self setPrintsHeader:NO];  // ヘッダ印刷の有無
        [self setPrintsFooter:NO];  // フッタ印刷の有無
        [self setPrintsHeaderSeparator:NO];
        [self setPrintsFooterSeparator:NO];
        [self setReadyToDrawPageNum:NO];
        [self setIsShowingLineNum:NO];
    }

    return self;
}


// ------------------------------------------------------
- (void)dealloc
// 後片づけ
// ------------------------------------------------------
{
    [[self filePath] release];
    [[self lineNumAttrs] release];
    [[self printValues] release];
    [[self headerFooterAttrs] release];
    [[self headerOneString] release];
    [[self headerTwoString] release];
    [[self footerOneString] release];
    [[self footerTwoString] release];

    [super dealloc];
}


// ------------------------------------------------------
- (void)drawPageBorderWithSize:(NSSize)borderSize
// ヘッダ／フッタの描画
// ------------------------------------------------------
{
    id values = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSRect currentFrame = [self frame]; // 現在のフレームを退避
    NSAttributedString *pageString = nil;
    NSPoint drawPoint = NSMakePoint(0.0, k_printHFVerticalMargin);
    CGFloat headerFooterLineFontSize = (CGFloat)[[values valueForKey:k_key_headerFooterFontSize] doubleValue];

    // プリントパネルでのカスタム設定を読み取り、保持
    if ([self readyToPrint] == NO) {
        [self setupPrintWithBorderWidth:borderSize.width];
    }
    // ページ番号の印字があるなら、準備する
    if ([self readyToDrawPageNum]) {
        NSInteger pageNum = [[NSPrintOperation currentOperation] currentPage];

        pageString = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"- %li -", (long)pageNum]
                                                      attributes:[self headerFooterAttrs]] autorelease];
    }

    // フレームを設定
    [self setFrame:NSMakeRect(0, 0, borderSize.width, borderSize.height)];

    // 描画開始
    // （このビューは isFlipped が YES なので drawAtPoint: は左上が原点となる）
    [self lockFocus];

    if ([self printsHeader]) {
        if ([self headerOneString]) {
            if ([[[self headerOneString] string] isEqualToString:@"PAGENUM"]) {
                [self setHeaderOneString:pageString];
            }
            drawPoint.x = [self xValueToDrawOfAttributedString:[self headerOneString]
                                                   borderWidth:borderSize.width alignment:[self headerOneAlignment]];
            [[self headerOneString] drawAtPoint:drawPoint];
            drawPoint.y += k_headerFooterLineHeight;
        }
        
        if ([self headerTwoString]) {
            if ([[[self headerTwoString] string] isEqualToString:@"PAGENUM"]) {
                [self setHeaderTwoString:pageString];
            }
            drawPoint.x = [self xValueToDrawOfAttributedString:[self headerTwoString]
                                                   borderWidth:borderSize.width alignment:[self headerTwoAlignment]];
            [[self headerTwoString] drawAtPoint:drawPoint];
            drawPoint.y += headerFooterLineFontSize;
            
        } else {
            if ([self headerOneString]) {
                drawPoint.y += headerFooterLineFontSize - k_headerFooterLineHeight;
            }
        }
    }
    if ([self printsHeaderSeparator]) {
        drawPoint.y += k_separatorPadding / 2;
        [[NSColor controlShadowColor] set];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(k_printHFHorizontalMargin, drawPoint.y)
                                  toPoint:NSMakePoint(borderSize.width - k_printHFHorizontalMargin, drawPoint.y)];
    }

    // （drawPoint.y を borderSize.height - k_printHFVerticalMargin とすると1ページに満たない書類の印刷時に
    // セパレータが印字されないので、フッタ全体を下げる。 2006.02.18）
    drawPoint.y = borderSize.height - k_printHFVerticalMargin + k_separatorPadding;
    if ([self printsFooter]) {
        if ([self footerTwoString]) {
            if ([[[self footerTwoString] string] isEqualToString:@"PAGENUM"]) {
                [self setFooterTwoString:pageString];
            }
            drawPoint.y -= k_headerFooterLineHeight;
            drawPoint.x = [self xValueToDrawOfAttributedString:[self footerTwoString]
                                                   borderWidth:borderSize.width alignment:[self footerTwoAlignment]];
            [[self footerTwoString] drawAtPoint:drawPoint];
        }
        
        if ([self footerOneString]) {
            if ([[[self footerOneString] string] isEqualToString:@"PAGENUM"]) {
                [self setFooterOneString:pageString];
            }
            drawPoint.y -= k_headerFooterLineHeight;
            drawPoint.x = [self xValueToDrawOfAttributedString:[self footerOneString]
                                                   borderWidth:borderSize.width alignment:[self footerOneAlignment]];
            [[self footerOneString] drawAtPoint:drawPoint];
        }
    }
    if ([self printsFooterSeparator]) {
        drawPoint.y -= k_separatorPadding / 2;
        [[NSColor controlShadowColor] set];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(k_printHFHorizontalMargin, drawPoint.y)
                                  toPoint:NSMakePoint(borderSize.width - k_printHFHorizontalMargin, drawPoint.y)];
    }
    [self unlockFocus];

    // フレームをもとに戻す
    [self setFrame:currentFrame];
}


// ------------------------------------------------------
- (void)drawRect:(NSRect)dirtyRect
// プリント
// ------------------------------------------------------
{
    [super drawRect:dirtyRect];

    // 行番号を印字
    if ([self printsLineNum]) {
        id values = [[NSUserDefaultsController sharedUserDefaultsController] values];
        CGFloat lineNumFontSize = (CGFloat)[[values valueForKey:k_key_lineNumFontSize] doubleValue];

        //文字幅を計算しておく 等幅扱い
        //いずれにしても等幅じゃないと奇麗に揃わないので等幅だということにしておく(hetima)
        CGFloat charWidth = [@"8" sizeWithAttributes:[self lineNumAttrs]].width;

        // setup the variables we need for the loop
        NSRange range;       // a range for counting lines
        NSString *str = [self string];
        NSString *numStr;    // a temporary string for Line Number
        NSString *wrappedLineMark = [[values valueForKey:k_key_showWrappedLineMark] boolValue] ? @"-:" : @" ";
        NSUInteger glyphIndex, theBefore, glyphCount; // glyph counter
        NSUInteger charIndex;
        NSUInteger lineNum;   // line counter
        CGFloat reqWidth;    // width calculator holder -- width needed to show string
        CGFloat xAdj = 0.0;    // adjust horizontal value for line number drawing
        CGFloat yAdj = 0.0;    // adjust vertical value for line number drawing
        NSRect numRect;      // rectange holder
        NSPoint numPoint;    // point holder
        NSLayoutManager *layoutManager = [self layoutManager]; // get _owner's layout manager.
        NSUInteger numberOfGlyphs = [layoutManager numberOfGlyphs];

        theBefore = 0;
        lineNum = 1;
        glyphCount = 0;
        xAdj = [self textContainerOrigin].x + k_printHFHorizontalMargin - k_lineNumPadding;
        yAdj = ([[self font] pointSize] - lineNumFontSize) / 2;

        for (glyphIndex = 0; glyphIndex < numberOfGlyphs; lineNum++) { // count "REAL" lines
            charIndex = [layoutManager characterIndexForGlyphAtIndex:glyphIndex];
            glyphIndex = NSMaxRange([layoutManager glyphRangeForCharacterRange:[str lineRangeForRange:NSMakeRange(charIndex, 0)]
                                                          actualCharacterRange:NULL]);
            while (glyphCount < glyphIndex) { // handle "DRAWN" (wrapped) lines
                numRect = [layoutManager lineFragmentRectForGlyphAtIndex:glyphCount effectiveRange:&range];
                if (NSPointInRect(numRect.origin, dirtyRect)) {
                    if (theBefore != lineNum) {
                        numStr = [NSString stringWithFormat:@"%ld:", (long)lineNum];
                        reqWidth = charWidth * [numStr length];
                    } else {
                        numStr = wrappedLineMark;
                        reqWidth = 8.0; // @"-:"のときに必要なピクセル値。変更時、注意。*****
                    }
                    numPoint = NSMakePoint(dirtyRect.origin.x - reqWidth + xAdj,
                                           numRect.origin.y + yAdj);
                    [numStr drawAtPoint:numPoint withAttributes:[self lineNumAttrs]]; // draw the line number.
                    theBefore = lineNum;
                }
                glyphCount = NSMaxRange(range);
            }
        }
    }
}


// ------------------------------------------------------
- (BOOL)isFlipped
// Y軸を逆転させる
// ------------------------------------------------------
{
    return YES;
}


// ------------------------------------------------------
- (NSPoint)textContainerOrigin
// the top/left point of text container.
// ------------------------------------------------------
{
    return NSMakePoint([self xOffset], 0.0);
}




#pragma mark -
#pragma mark Public Methods

//=======================================================
// Private method
//
//=======================================================

// ------------------------------------------------------
- (void)setupPrintWithBorderWidth:(CGFloat)borderWidth
// プリント開始の準備
// ------------------------------------------------------
{
    id values = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSAttributedString *attrString = nil;
    CGFloat printWidth = borderWidth - k_printHFHorizontalMargin * 2;
    NSInteger lineNumMenuIndex = [[[self printValues] valueForKey:k_printLineNumIndex] integerValue];

    // ヘッダ／フッタの文字属性辞書生成、保持
    NSFont *headerFooterFont = [NSFont fontWithName:[values valueForKey:k_key_headerFooterFontName]
                                               size:(CGFloat)[[values valueForKey:k_key_headerFooterFontSize] doubleValue]];
    [self setHeaderFooterAttrs:@{NSFontAttributeName: headerFooterFont,
                                 NSForegroundColorAttributeName: [NSColor textColor]}]; // ===== retain

    // 行番号印字の有無をチェック
    if (lineNumMenuIndex == 1) { // same to view
        [self setPrintsLineNum:[self isShowingLineNum]];
    } else if (lineNumMenuIndex == 2) { // print
        [self setPrintsLineNum:YES];
    } else {
        [self setPrintsLineNum:NO];
    }

    // 行番号を印字するときは文字属性を保持、パディングを調整
    if ([self printsLineNum]) {
        NSFont *font = [NSFont fontWithName:[values valueForKey:k_key_lineNumFontName]
                                       size:(CGFloat)[[values valueForKey:k_key_lineNumFontSize] doubleValue]];
        [self setLineNumAttrs:@{NSFontAttributeName:font,
                                NSForegroundColorAttributeName:[NSUnarchiver unarchiveObjectWithData:[values valueForKey:k_key_lineNumFontColor]]}]; // ===== retain
        [self setXOffset:k_printTextHorizontalMargin];
    }
    
    // ヘッダを設定
    if ([[[self printValues] valueForKey:k_printHeader] boolValue]) {
        [self setPrintsHeader:YES];
        attrString = [self attributedStringFromPrintInfoSelectedIndex:[[[self printValues] valueForKey:k_headerOneStringIndex] integerValue]
                                                             maxWidth:printWidth];
        [self setHeaderOneString:attrString];
        attrString = [self attributedStringFromPrintInfoSelectedIndex:[[[self printValues] valueForKey:k_headerTwoStringIndex] integerValue]
                                                             maxWidth:printWidth];
        [self setHeaderTwoString:attrString];
        [self setHeaderOneAlignment:[[[self printValues] valueForKey:k_headerOneAlignIndex] integerValue]];
        [self setHeaderTwoAlignment:[[[self printValues] valueForKey:k_headerTwoAlignIndex] integerValue]];
    } else {
        [self setPrintsHeader:NO];
    }
    [self setPrintsHeaderSeparator:[[[self printValues] valueForKey:k_printHeaderSeparator] boolValue]];

    // フッタを設定
    if ([[[self printValues] valueForKey:k_printFooter] boolValue]) {
        [self setPrintsFooter:YES];
        attrString = [self attributedStringFromPrintInfoSelectedIndex:[[[self printValues] valueForKey:k_footerOneStringIndex] integerValue]
                                                             maxWidth:printWidth];
        [self setFooterOneString:attrString];
        attrString = [self attributedStringFromPrintInfoSelectedIndex:[[[self printValues] valueForKey:k_footerTwoStringIndex] integerValue]
                                                             maxWidth:printWidth];
        [self setFooterTwoString:attrString];
        [self setFooterOneAlignment:[[[self printValues] valueForKey:k_footerOneAlignIndex] integerValue]];
        [self setFooterTwoAlignment:[[[self printValues] valueForKey:k_footerTwoAlignIndex] integerValue]];
    } else {
        [self setPrintsFooter:NO];
    }
    [self setPrintsFooterSeparator:[[[self printValues] valueForKey:k_printFooterSeparator] boolValue]];
    [self setReadyToPrint:YES];
}


// ------------------------------------------------------
- (NSAttributedString *)attributedStringFromPrintInfoSelectedIndex:(NSInteger)selectedIndex maxWidth:(CGFloat)maxWidth
// ヘッダ／フッタに印字する文字列をポップアップメニューインデックスから生成し、返す
// ------------------------------------------------------
{
    id values = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSAttributedString *outString = nil;
    NSString *dateString;
            
    switch (selectedIndex) {
        case 2: // == Document Name
            if ([self filePath]) {
                outString = [[[NSAttributedString alloc] initWithString:[[self filePath] lastPathComponent]
                                                             attributes:[self headerFooterAttrs]] autorelease];
            }
            break;

        case 3: // == File Path
            if ([self filePath]) {
                outString = [[[NSAttributedString alloc] initWithString:[self filePath]
                                                             attributes:[self headerFooterAttrs]] autorelease];
            }
            break;

        case 4: // == Print Date
            dateString = [[NSCalendarDate calendarDate] descriptionWithCalendarFormat:[values valueForKey:k_key_headerFooterDateTimeFormat]];
            if (dateString && ([dateString length] > 0)) {
                outString = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"Printed: %@",@""),
                                                                         dateString]
                                                             attributes:[self headerFooterAttrs]] autorelease];
            }
            break;

        case 5: // == Page num
            outString = [[[NSAttributedString alloc] initWithString:@"PAGENUM"
                                                         attributes:[self headerFooterAttrs]] autorelease];
            [self setReadyToDrawPageNum:YES];
            break;

        default:
            break;
    }

    // 印字があふれる場合、中ほどを省略する
    if ([outString size].width > maxWidth) {
        NSMutableAttributedString *attrStr = [[outString mutableCopy] autorelease];
        NSUInteger length = [attrStr length];
        CGFloat width = [attrStr size].width;
        if (length > 0) {
            CGFloat average = width / length;
            NSInteger deleteCount = (width - maxWidth) / average + 5; // 置き換える5文字の幅をみる
            NSRange replaceRange = NSMakeRange((NSUInteger)((length - deleteCount) / 2), deleteCount);
            [attrStr replaceCharactersInRange:replaceRange withString:@" ... "];
        }
        return attrStr;
    }

    return outString;
}


// ------------------------------------------------------
- (CGFloat)xValueToDrawOfAttributedString:(NSAttributedString *)attrString
                              borderWidth:(CGFloat)borderWidth
                                alignment:(CEAlignmentType)alignmentType
// X軸方向の印字開始位置を返す
// ------------------------------------------------------
{
    switch (alignmentType) {
        case CEAlignCenter:
            return (borderWidth - [attrString size].width) / 2;
            break;
        case CEAlignRight:
            return (borderWidth - [attrString size].width) - k_printHFHorizontalMargin;
            break;
        default:
            return k_printHFHorizontalMargin;
            break;
    }
}

@end
