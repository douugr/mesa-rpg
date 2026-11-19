#import "TTModel.h"

static const CGFloat kTTMaxImageSide = 3072;

UIColor *TTTokenColor(NSInteger i) {
    static const CGFloat c[8][3] = {
        {0.78, 0.18, 0.20},  // vermelho
        {0.18, 0.42, 0.80},  // azul
        {0.14, 0.58, 0.30},  // verde
        {0.55, 0.28, 0.72},  // roxo
        {0.88, 0.50, 0.10},  // laranja
        {0.08, 0.60, 0.62},  // turquesa
        {0.80, 0.66, 0.08},  // amarelo
        {0.40, 0.40, 0.44},  // cinza
    };
    NSInteger k = ((i % 8) + 8) % 8;
    return [UIColor colorWithRed:c[k][0] green:c[k][1] blue:c[k][2] alpha:1.0];
}

NSInteger TTTokenColorCount(void) {
    return 8;
}

static NSString *TTNewId(void) {
    return [[NSUUID UUID] UUIDString];
}

#pragma mark - TTToken

@implementation TTToken

- (instancetype)init {
    if ((self = [super init])) {
        _tokenId = TTNewId();
        _name = @"Token";
        _label = @"";
        _size = 1;
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)d {
    if ((self = [self init])) {
        if ([d[@"id"] isKindOfClass:[NSString class]]) _tokenId = [d[@"id"] copy];
        if ([d[@"name"] isKindOfClass:[NSString class]]) _name = [d[@"name"] copy];
        if ([d[@"label"] isKindOfClass:[NSString class]]) _label = [d[@"label"] copy];
        _col = [d[@"col"] integerValue];
        _row = [d[@"row"] integerValue];
        _size = MAX(1, [d[@"size"] integerValue]);
        _colorIndex = [d[@"color"] integerValue];
        _hp = [d[@"hp"] integerValue];
        _maxHp = [d[@"maxHp"] integerValue];
        _down = [d[@"down"] boolValue];
    }
    return self;
}

- (NSDictionary *)dictionaryRepresentation {
    return @{ @"id": self.tokenId, @"name": self.name ?: @"", @"label": self.label ?: @"",
              @"col": @(self.col), @"row": @(self.row), @"size": @(self.size),
              @"color": @(self.colorIndex), @"hp": @(self.hp), @"maxHp": @(self.maxHp),
              @"down": @(self.down) };
}

- (TTToken *)duplicate {
    TTToken *t = [[TTToken alloc] initWithDictionary:[self dictionaryRepresentation]];
    t.tokenId = TTNewId();
    return t;
}

@end

#pragma mark - TTScene

@implementation TTScene

- (instancetype)init {
    if ((self = [super init])) {
        _sceneId = TTNewId();
        _name = @"Scene";
        _boardWidth = 2048;
        _boardHeight = 1536;
        _cellSize = 2048.0 / 24.0;
        _gridVisible = YES;
        _gridAlpha = 0.45;
        _metersPerCell = 2;
        _tokens = [NSMutableArray array];
        _turnIndex = -1;
        _round = 1;
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)d {
    if ((self = [self init])) {
        if ([d[@"id"] isKindOfClass:[NSString class]]) _sceneId = [d[@"id"] copy];
        if ([d[@"name"] isKindOfClass:[NSString class]]) _name = [d[@"name"] copy];
        if ([d[@"image"] isKindOfClass:[NSString class]]) _imageFile = [d[@"image"] copy];
        if (d[@"w"]) _boardWidth = [d[@"w"] doubleValue];
        if (d[@"h"]) _boardHeight = [d[@"h"] doubleValue];
        if (d[@"cell"]) _cellSize = MAX(8, [d[@"cell"] doubleValue]);
        _offsetX = [d[@"ox"] doubleValue];
        _offsetY = [d[@"oy"] doubleValue];
        if (d[@"grid"]) _gridVisible = [d[@"grid"] boolValue];
        if (d[@"alpha"]) _gridAlpha = [d[@"alpha"] doubleValue];
        if (d[@"meters"]) _metersPerCell = [d[@"meters"] doubleValue];
        if (d[@"turn"]) _turnIndex = [d[@"turn"] integerValue];
        if (d[@"round"]) _round = MAX(1, [d[@"round"] integerValue]);
        id tokens = d[@"tokens"];
        if ([tokens isKindOfClass:[NSArray class]]) {
            for (id td in tokens) {
                if ([td isKindOfClass:[NSDictionary class]]) {
                    [_tokens addObject:[[TTToken alloc] initWithDictionary:td]];
                }
            }
        }
    }
    return self;
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableArray *tokens = [NSMutableArray array];
    for (TTToken *t in self.tokens) {
        [tokens addObject:[t dictionaryRepresentation]];
    }
    NSMutableDictionary *d = [@{ @"id": self.sceneId, @"name": self.name ?: @"",
                                 @"w": @(self.boardWidth), @"h": @(self.boardHeight),
                                 @"cell": @(self.cellSize), @"ox": @(self.offsetX), @"oy": @(self.offsetY),
                                 @"grid": @(self.gridVisible), @"alpha": @(self.gridAlpha),
                                 @"meters": @(self.metersPerCell), @"turn": @(self.turnIndex),
                                 @"round": @(self.round), @"tokens": tokens } mutableCopy];
    if (self.imageFile) d[@"image"] = self.imageFile;
    return d;
}

- (UIImage *)loadImage {
    if (!self.imageFile) return nil;
    NSString *path = [[TTStore mapsPath] stringByAppendingPathComponent:self.imageFile];
    return [UIImage imageWithContentsOfFile:path];
}

@end

#pragma mark - TTStore

@implementation TTStore

+ (NSString *)documentsPath {
    return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
}

+ (NSString *)supportPath {
    NSString *base = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES).firstObject;
    NSString *path = [base stringByAppendingPathComponent:@"Tabletop"];
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    return path;
}

+ (NSString *)mapsPath {
    NSString *path = [[self supportPath] stringByAppendingPathComponent:@"maps"];
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    return path;
}

+ (NSString *)statePath {
    return [[self supportPath] stringByAppendingPathComponent:@"state.plist"];
}

+ (instancetype)load {
    TTStore *store = [[TTStore alloc] init];
    store.scenes = [NSMutableArray array];
    NSDictionary *state = [NSDictionary dictionaryWithContentsOfFile:[self statePath]];
    id scenes = state[@"scenes"];
    if ([scenes isKindOfClass:[NSArray class]]) {
        for (id sd in scenes) {
            if ([sd isKindOfClass:[NSDictionary class]]) {
                [store.scenes addObject:[[TTScene alloc] initWithDictionary:sd]];
            }
        }
    }
    if (store.scenes.count == 0) {
        [store addSceneNamed:@"Scene 1"];
    }
    NSInteger idx = [state[@"current"] integerValue];
    store.currentIndex = (idx >= 0 && idx < (NSInteger)store.scenes.count) ? idx : 0;
    return store;
}

- (TTScene *)currentScene {
    return self.scenes[self.currentIndex];
}

- (TTScene *)addSceneNamed:(NSString *)name {
    TTScene *scene = [[TTScene alloc] init];
    scene.name = name;
    [self.scenes addObject:scene];
    self.currentIndex = self.scenes.count - 1;
    [self save];
    return scene;
}

- (void)removeCurrentScene {
    if (self.scenes.count <= 1) return;
    TTScene *scene = [self currentScene];
    [self removeMapForScene:scene];
    [self.scenes removeObjectAtIndex:self.currentIndex];
    self.currentIndex = MAX(0, self.currentIndex - 1);
    [self save];
}

- (void)save {
    NSMutableArray *scenes = [NSMutableArray array];
    for (TTScene *s in self.scenes) {
        [scenes addObject:[s dictionaryRepresentation]];
    }
    NSDictionary *state = @{ @"current": @(self.currentIndex), @"scenes": scenes };
    [state writeToFile:[TTStore statePath] atomically:YES];
}

+ (BOOL)parseGridFromFileName:(NSString *)fileName cellSize:(CGFloat *)cellSize meters:(CGFloat *)meters {
    static NSRegularExpression *re;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        re = [NSRegularExpression regularExpressionWithPattern:@"(?:quadrado|square|grid)\\s+([0-9]+(?:[.,][0-9]+)?)\\s*px(?:\\s*\\(\\s*([0-9]+(?:[.,][0-9]+)?)\\s*m\\s*\\))?"
                                                       options:NSRegularExpressionCaseInsensitive
                                                         error:nil];
    });
    if (!fileName.length) return NO;
    NSTextCheckingResult *m = [re firstMatchInString:fileName options:0 range:NSMakeRange(0, fileName.length)];
    if (!m) return NO;
    NSString *px = [[fileName substringWithRange:[m rangeAtIndex:1]] stringByReplacingOccurrencesOfString:@"," withString:@"."];
    CGFloat size = [px doubleValue];
    if (size <= 0) return NO;
    if (cellSize) *cellSize = size;
    if (meters) {
        *meters = 0;
        if ([m rangeAtIndex:2].location != NSNotFound) {
            NSString *mt = [[fileName substringWithRange:[m rangeAtIndex:2]] stringByReplacingOccurrencesOfString:@"," withString:@"."];
            *meters = [mt doubleValue];
        }
    }
    return YES;
}

- (void)setMapImage:(UIImage *)image forScene:(TTScene *)scene {
    [self setMapImage:image forScene:scene cellSize:0 meters:0];
}

- (void)setMapImage:(UIImage *)image forScene:(TTScene *)scene cellSize:(CGFloat)hintCell meters:(CGFloat)hintMeters {
    if (!image) return;
    CGSize src = image.size;
    CGFloat scale = MIN(1.0, kTTMaxImageSide / MAX(src.width, src.height));
    CGSize dst = CGSizeMake(floor(src.width * scale), floor(src.height * scale));

    // Redesenha: reduz o tamanho e corrige a orientação da foto
    UIGraphicsBeginImageContextWithOptions(dst, YES, 1.0);
    [image drawInRect:CGRectMake(0, 0, dst.width, dst.height)];
    UIImage *resized = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    NSData *jpeg = UIImageJPEGRepresentation(resized, 0.85);
    if (!jpeg) return;

    [self removeMapForScene:scene];
    NSString *file = [NSString stringWithFormat:@"%@.jpg", [[NSUUID UUID] UUIDString]];
    [jpeg writeToFile:[[TTStore mapsPath] stringByAppendingPathComponent:file] atomically:YES];

    CGFloat oldCell = scene.cellSize;
    CGFloat oldWidth = scene.boardWidth;
    scene.imageFile = file;
    scene.boardWidth = dst.width;
    scene.boardHeight = dst.height;
    if (hintCell > 0) {
        // Grid informado no nome do arquivo, em pixels da imagem original
        // (dst está em pixels; image.size em pontos, então pixels originais = size × image.scale)
        CGFloat pixelScale = scale / (image.scale > 0 ? image.scale : 1.0);
        scene.cellSize = MAX(8, hintCell * pixelScale);
    } else {
        // Mantém a proporção do grid em relação à largura da mesa
        scene.cellSize = MAX(8, oldCell * (dst.width / MAX(1, oldWidth)));
    }
    if (hintMeters > 0) {
        scene.metersPerCell = hintMeters;
    }
    scene.offsetX = 0;
    scene.offsetY = 0;
    [self save];
}

- (void)removeMapForScene:(TTScene *)scene {
    if (scene.imageFile) {
        NSString *path = [[TTStore mapsPath] stringByAppendingPathComponent:scene.imageFile];
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        scene.imageFile = nil;
    }
}

@end
