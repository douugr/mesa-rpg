#import <UIKit/UIKit.h>

UIColor *TTTokenColor(NSInteger index);
NSInteger TTTokenColorCount(void);

@interface TTToken : NSObject
@property (nonatomic, copy) NSString *tokenId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *label;   // até 3 caracteres, aparece no círculo
@property (nonatomic, assign) NSInteger col;   // posição em quadrados (canto superior esquerdo)
@property (nonatomic, assign) NSInteger row;
@property (nonatomic, assign) NSInteger size;  // 1 = 1x1 quadrado, 2 = 2x2...
@property (nonatomic, assign) NSInteger colorIndex;
@property (nonatomic, assign) NSInteger hp;
@property (nonatomic, assign) NSInteger maxHp; // 0 = não mostra PV
@property (nonatomic, assign) BOOL down;       // caído / fora de combate

- (NSDictionary *)dictionaryRepresentation;
- (instancetype)initWithDictionary:(NSDictionary *)d;
- (TTToken *)duplicate;
@end

@interface TTScene : NSObject
@property (nonatomic, copy) NSString *sceneId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *imageFile;   // nome do arquivo em mapsPath; nil = sem mapa
@property (nonatomic, assign) CGFloat boardWidth;  // tamanho da mesa em pontos (= pixels da imagem)
@property (nonatomic, assign) CGFloat boardHeight;
@property (nonatomic, assign) CGFloat cellSize;    // lado do quadrado, em pontos da mesa
@property (nonatomic, assign) CGFloat offsetX;     // deslocamento do grid
@property (nonatomic, assign) CGFloat offsetY;
@property (nonatomic, assign) BOOL gridVisible;
@property (nonatomic, assign) CGFloat gridAlpha;
@property (nonatomic, assign) CGFloat metersPerCell;
@property (nonatomic, strong) NSMutableArray *tokens; // também é a ordem de iniciativa
@property (nonatomic, assign) NSInteger turnIndex;    // -1 = combate não iniciado
@property (nonatomic, assign) NSInteger round;

- (NSDictionary *)dictionaryRepresentation;
- (instancetype)initWithDictionary:(NSDictionary *)d;
- (UIImage *)loadImage;
@end

@interface TTStore : NSObject
@property (nonatomic, strong) NSMutableArray *scenes;
@property (nonatomic, assign) NSInteger currentIndex;

+ (instancetype)load;
+ (NSString *)documentsPath;
+ (NSString *)mapsPath;
- (TTScene *)currentScene;
- (TTScene *)addSceneNamed:(NSString *)name;
- (void)removeCurrentScene;
- (void)save;
// Redimensiona a imagem (no máx. 3072 px), grava como JPEG e associa à cena
- (void)setMapImage:(UIImage *)image forScene:(TTScene *)scene;
- (void)removeMapForScene:(TTScene *)scene;
@end
