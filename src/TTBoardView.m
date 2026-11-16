#import "TTBoardView.h"
#import "TTModel.h"
#import <QuartzCore/QuartzCore.h>

#pragma mark - TTTokenView

@interface TTTokenView : UIView
@property (nonatomic, strong) TTToken *token;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UILabel *hpLabel;
@property (nonatomic, strong) CAShapeLayer *crossLayer;
@property (nonatomic, assign) BOOL activeTurn;
- (void)refresh;
@end

@implementation TTTokenView

- (instancetype)initWithToken:(TTToken *)token {
    if ((self = [super initWithFrame:CGRectZero])) {
        _token = token;
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOpacity = 0.6;
        self.layer.shadowOffset = CGSizeMake(0, 2);

        _label = [[UILabel alloc] init];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.textColor = [UIColor whiteColor];
        _label.adjustsFontSizeToFitWidth = YES;
        _label.minimumScaleFactor = 0.4;
        [self addSubview:_label];

        _hpLabel = [[UILabel alloc] init];
        _hpLabel.textAlignment = NSTextAlignmentCenter;
        _hpLabel.adjustsFontSizeToFitWidth = YES;
        _hpLabel.minimumScaleFactor = 0.4;
        [self addSubview:_hpLabel];

        _crossLayer = [CAShapeLayer layer];
        _crossLayer.strokeColor = [UIColor colorWithWhite:0 alpha:0.75].CGColor;
        _crossLayer.lineCap = kCALineCapRound;
        [self.layer addSublayer:_crossLayer];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.bounds.size.width;
    self.layer.cornerRadius = w / 2.0;
    self.layer.shadowRadius = w * 0.05;
    self.label.frame = CGRectMake(w * 0.12, w * 0.18, w * 0.76, w * 0.48);
    self.label.font = [UIFont boldSystemFontOfSize:w * 0.4];
    self.hpLabel.frame = CGRectMake(w * 0.18, w * 0.64, w * 0.64, w * 0.2);
    self.hpLabel.font = [UIFont boldSystemFontOfSize:w * 0.16];

    UIBezierPath *x = [UIBezierPath bezierPath];
    CGFloat a = w * 0.22, b = w * 0.78;
    [x moveToPoint:CGPointMake(a, a)];
    [x addLineToPoint:CGPointMake(b, b)];
    [x moveToPoint:CGPointMake(b, a)];
    [x addLineToPoint:CGPointMake(a, b)];
    self.crossLayer.frame = self.bounds;
    self.crossLayer.path = x.CGPath;
    self.crossLayer.lineWidth = w * 0.1;
    [self refresh];
}

- (void)refresh {
    CGFloat w = self.bounds.size.width;
    TTToken *t = self.token;
    self.backgroundColor = TTTokenColor(t.colorIndex);
    self.label.text = t.label.length ? t.label : [t.name substringToIndex:MIN((NSUInteger)2, t.name.length)];
    if (self.activeTurn) {
        self.layer.borderColor = [UIColor colorWithRed:1 green:0.85 blue:0.1 alpha:1].CGColor;
        self.layer.borderWidth = MAX(2, w * 0.09);
    } else {
        self.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.9].CGColor;
        self.layer.borderWidth = MAX(1, w * 0.035);
    }
    if (t.maxHp > 0) {
        self.hpLabel.hidden = NO;
        self.hpLabel.text = [NSString stringWithFormat:@"%ld/%ld", (long)t.hp, (long)t.maxHp];
        if (t.hp <= 0) {
            self.hpLabel.textColor = [UIColor colorWithRed:1 green:0.45 blue:0.45 alpha:1];
        } else if (t.hp * 2 <= t.maxHp) {
            // Cyberpunk RED: abaixo da metade = gravemente ferido
            self.hpLabel.textColor = [UIColor colorWithRed:1 green:0.82 blue:0.35 alpha:1];
        } else {
            self.hpLabel.textColor = [UIColor whiteColor];
        }
    } else {
        self.hpLabel.hidden = YES;
    }
    self.crossLayer.hidden = !t.down;
    self.alpha = t.down ? 0.6 : 1.0;
}

@end

#pragma mark - TTBoardView

@interface TTBoardView () <UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) CAShapeLayer *gridLayer;
@property (nonatomic, strong) NSMutableArray *tokenViews;

@property (nonatomic, strong) CAShapeLayer *rulerLayer;
@property (nonatomic, strong) UILabel *rulerLabel;

@property (nonatomic, weak) TTTokenView *draggingView;
@property (nonatomic, assign) CGPoint dragOffset;
@property (nonatomic, assign) CGPoint dragStartCell;
@property (nonatomic, assign) CGPoint rulerStart;
@end

@implementation TTBoardView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor colorWithRed:0.10 green:0.11 blue:0.13 alpha:1];
        _tokenViews = [NSMutableArray array];

        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleToFill;
        [self addSubview:_imageView];

        _gridLayer = [CAShapeLayer layer];
        _gridLayer.fillColor = nil;
        [self.layer addSublayer:_gridLayer];

        _rulerLayer = [CAShapeLayer layer];
        _rulerLayer.strokeColor = [UIColor colorWithRed:1 green:0.85 blue:0.1 alpha:1].CGColor;
        _rulerLayer.fillColor = [UIColor colorWithRed:1 green:0.85 blue:0.1 alpha:1].CGColor;
        _rulerLayer.lineCap = kCALineCapRound;
        _rulerLayer.hidden = YES;

        _rulerLabel = [[UILabel alloc] init];
        _rulerLabel.textColor = [UIColor whiteColor];
        _rulerLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.75];
        _rulerLabel.textAlignment = NSTextAlignmentCenter;
        _rulerLabel.layer.cornerRadius = 6;
        _rulerLabel.clipsToBounds = YES;
        _rulerLabel.hidden = YES;

        UIPanGestureRecognizer *ruler = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleRulerPan:)];
        ruler.maximumNumberOfTouches = 1;
        ruler.delegate = self;
        [self addGestureRecognizer:ruler];
    }
    return self;
}

#pragma mark Geometry

- (CGFloat)cell {
    return MAX(8, self.scene.cellSize);
}

- (CGPoint)cellForPoint:(CGPoint)p {
    return CGPointMake(floor((p.x - self.scene.offsetX) / [self cell]),
                       floor((p.y - self.scene.offsetY) / [self cell]));
}

- (CGPoint)centerOfCell:(CGPoint)c {
    CGFloat s = [self cell];
    return CGPointMake(self.scene.offsetX + (c.x + 0.5) * s, self.scene.offsetY + (c.y + 0.5) * s);
}

- (CGRect)rectForToken:(TTToken *)t {
    CGFloat s = [self cell];
    CGRect r = CGRectMake(self.scene.offsetX + t.col * s, self.scene.offsetY + t.row * s, t.size * s, t.size * s);
    return CGRectInset(r, s * 0.06, s * 0.06);
}

// Coluna/linha do canto superior esquerdo de um token de tamanho `size` centrado em `center`
- (CGPoint)originCellForCenter:(CGPoint)center size:(NSInteger)size {
    CGFloat s = [self cell];
    NSInteger col = (NSInteger)lround((center.x - self.scene.offsetX) / s - size / 2.0);
    NSInteger row = (NSInteger)lround((center.y - self.scene.offsetY) / s - size / 2.0);
    NSInteger maxCol = (NSInteger)floor((self.scene.boardWidth - self.scene.offsetX) / s) - size;
    NSInteger maxRow = (NSInteger)floor((self.scene.boardHeight - self.scene.offsetY) / s) - size;
    NSInteger minCol = self.scene.offsetX > 0.5 ? -1 : 0;
    NSInteger minRow = self.scene.offsetY > 0.5 ? -1 : 0;
    col = MAX(minCol, MIN(MAX(minCol, maxCol), col));
    row = MAX(minRow, MIN(MAX(minRow, maxRow), row));
    return CGPointMake(col, row);
}

- (NSString *)distanceTextFrom:(CGPoint)a to:(CGPoint)b {
    // Diagonal conta como 1 quadrado (Cyberpunk RED / D&D 5e)
    NSInteger d = (NSInteger)MAX(fabs(a.x - b.x), fabs(a.y - b.y));
    double meters = d * self.scene.metersPerCell;
    return [NSString stringWithFormat:@"  %ld quad. · %g m  ", (long)d, meters];
}

#pragma mark Reload

- (void)reloadAll {
    UIImage *image = [self.scene loadImage];
    self.imageView.image = image;
    self.imageView.hidden = (image == nil);
    CGRect bounds = CGRectMake(0, 0, self.scene.boardWidth, self.scene.boardHeight);
    self.bounds = bounds;
    self.imageView.frame = bounds;
    [self reloadGrid];
    [self reloadTokens];
}

- (void)reloadGrid {
    CGFloat W = self.scene.boardWidth, H = self.scene.boardHeight, s = [self cell];
    self.gridLayer.frame = CGRectMake(0, 0, W, H);
    self.gridLayer.hidden = !self.scene.gridVisible;
    self.gridLayer.strokeColor = [UIColor colorWithWhite:1 alpha:self.scene.gridAlpha].CGColor;
    self.gridLayer.lineWidth = MAX(1, s * 0.025);

    UIBezierPath *path = [UIBezierPath bezierPath];
    CGFloat x0 = fmod(self.scene.offsetX, s);
    if (x0 < 0) x0 += s;
    for (CGFloat x = x0; x <= W + 0.5; x += s) {
        [path moveToPoint:CGPointMake(x, 0)];
        [path addLineToPoint:CGPointMake(x, H)];
    }
    CGFloat y0 = fmod(self.scene.offsetY, s);
    if (y0 < 0) y0 += s;
    for (CGFloat y = y0; y <= H + 0.5; y += s) {
        [path moveToPoint:CGPointMake(0, y)];
        [path addLineToPoint:CGPointMake(W, y)];
    }
    self.gridLayer.path = path.CGPath;

    for (TTTokenView *tv in self.tokenViews) {
        tv.frame = [self rectForToken:tv.token];
    }
}

- (void)reloadTokens {
    for (UIView *v in self.tokenViews) {
        [v removeFromSuperview];
    }
    [self.tokenViews removeAllObjects];

    NSInteger i = 0;
    for (TTToken *t in self.scene.tokens) {
        TTTokenView *tv = [[TTTokenView alloc] initWithToken:t];
        tv.activeTurn = (i == self.scene.turnIndex);
        tv.frame = [self rectForToken:t];

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTokenTap:)];
        [tv addGestureRecognizer:tap];
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleTokenPan:)];
        pan.maximumNumberOfTouches = 1;
        [tv addGestureRecognizer:pan];

        [self addSubview:tv];
        [self.tokenViews addObject:tv];
        [tv refresh];
        i++;
    }
    // Token da vez sempre por cima
    if (self.scene.turnIndex >= 0 && self.scene.turnIndex < (NSInteger)self.tokenViews.count) {
        [self bringSubviewToFront:self.tokenViews[self.scene.turnIndex]];
    }
    [self.layer addSublayer:self.rulerLayer];
    [self addSubview:self.rulerLabel];
}

- (void)zoomDidChange {
    if (!self.rulerLabel.hidden) {
        [self positionRulerLabelAt:self.rulerLabel.center];
    }
}

#pragma mark Ruler

- (CGFloat)zoom {
    CGFloat z = [self.delegate zoomScaleForBoard:self];
    return z > 0 ? z : 1;
}

- (void)positionRulerLabelAt:(CGPoint)p {
    CGFloat z = [self zoom];
    self.rulerLabel.font = [UIFont boldSystemFontOfSize:18.0 / z];
    [self.rulerLabel sizeToFit];
    CGRect f = self.rulerLabel.frame;
    f.size.height = 30.0 / z;
    self.rulerLabel.frame = f;
    self.rulerLabel.layer.cornerRadius = 6.0 / z;
    self.rulerLabel.center = p;
}

- (void)showRulerFrom:(CGPoint)a to:(CGPoint)b text:(NSString *)text {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideRuler) object:nil];
    CGFloat z = [self zoom];
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:a];
    [path addLineToPoint:b];
    CGFloat r = 6.0 / z;
    [path appendPath:[UIBezierPath bezierPathWithOvalInRect:CGRectMake(a.x - r, a.y - r, 2 * r, 2 * r)]];
    [path appendPath:[UIBezierPath bezierPathWithOvalInRect:CGRectMake(b.x - r, b.y - r, 2 * r, 2 * r)]];
    self.rulerLayer.frame = self.bounds;
    self.rulerLayer.path = path.CGPath;
    self.rulerLayer.lineWidth = 4.0 / z;
    self.rulerLayer.lineDashPattern = @[@(10.0 / z), @(6.0 / z)];
    self.rulerLayer.hidden = NO;

    self.rulerLabel.text = text;
    self.rulerLabel.hidden = NO;
    [self positionRulerLabelAt:CGPointMake(b.x, b.y - 40.0 / z)];
    [self bringSubviewToFront:self.rulerLabel];
}

- (void)hideRulerSoon {
    [self performSelector:@selector(hideRuler) withObject:nil afterDelay:1.5];
}

- (void)hideRuler {
    self.rulerLayer.hidden = YES;
    self.rulerLabel.hidden = YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)g shouldReceiveTouch:(UITouch *)touch {
    // A régua só começa em área vazia da mesa (não em cima de token)
    UIView *v = touch.view;
    while (v && v != self) {
        if ([v isKindOfClass:[TTTokenView class]]) return NO;
        v = v.superview;
    }
    return YES;
}

- (void)handleRulerPan:(UIPanGestureRecognizer *)g {
    CGPoint p = [g locationInView:self];
    if (g.state == UIGestureRecognizerStateBegan) {
        self.rulerStart = [self cellForPoint:p];
    }
    CGPoint endCell = [self cellForPoint:p];
    if (g.state == UIGestureRecognizerStateBegan || g.state == UIGestureRecognizerStateChanged) {
        [self showRulerFrom:[self centerOfCell:self.rulerStart]
                         to:[self centerOfCell:endCell]
                       text:[self distanceTextFrom:self.rulerStart to:endCell]];
    } else {
        [self hideRulerSoon];
    }
}

#pragma mark Tokens

- (void)handleTokenTap:(UITapGestureRecognizer *)g {
    TTTokenView *tv = (TTTokenView *)g.view;
    [self.delegate board:self didTapToken:tv.token];
}

- (void)handleTokenPan:(UIPanGestureRecognizer *)g {
    TTTokenView *tv = (TTTokenView *)g.view;
    TTToken *t = tv.token;
    CGPoint p = [g locationInView:self];

    switch (g.state) {
        case UIGestureRecognizerStateBegan: {
            self.draggingView = tv;
            self.dragOffset = CGPointMake(p.x - tv.center.x, p.y - tv.center.y);
            self.dragStartCell = CGPointMake(t.col, t.row);
            [self bringSubviewToFront:tv];
            [UIView animateWithDuration:0.12 animations:^{
                tv.transform = CGAffineTransformMakeScale(1.12, 1.12);
            }];
            break;
        }
        case UIGestureRecognizerStateChanged: {
            CGPoint center = CGPointMake(p.x - self.dragOffset.x, p.y - self.dragOffset.y);
            tv.center = center;
            CGPoint target = [self originCellForCenter:center size:t.size];
            CGPoint startCenter = CGPointMake(CGRectGetMidX([self rectForToken:t]), CGRectGetMidY([self rectForToken:t]));
            CGFloat half = (t.size - 1) / 2.0;
            CGPoint targetCenter = [self centerOfCell:CGPointMake(target.x + half, target.y + half)];
            [self showRulerFrom:startCenter to:targetCenter text:[self distanceTextFrom:self.dragStartCell to:target]];
            break;
        }
        default: {
            CGPoint center = CGPointMake(p.x - self.dragOffset.x, p.y - self.dragOffset.y);
            if (g.state == UIGestureRecognizerStateEnded) {
                CGPoint target = [self originCellForCenter:center size:t.size];
                t.col = (NSInteger)target.x;
                t.row = (NSInteger)target.y;
            }
            [UIView animateWithDuration:0.15 animations:^{
                tv.transform = CGAffineTransformIdentity;
                tv.frame = [self rectForToken:t];
            }];
            self.draggingView = nil;
            [self hideRulerSoon];
            [self.delegate boardDidChange:self];
            break;
        }
    }
}

@end
