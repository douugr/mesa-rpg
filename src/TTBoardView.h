#import <UIKit/UIKit.h>

@class TTScene, TTToken, TTBoardView;

@protocol TTBoardViewDelegate <NSObject>
- (void)board:(TTBoardView *)board didTapToken:(TTToken *)token;
- (void)boardDidChange:(TTBoardView *)board;
- (CGFloat)zoomScaleForBoard:(TTBoardView *)board;
@end

// A "mesa": mapa + grid + tokens + régua. Coordenadas em pontos da mesa (= pixels do mapa).
@interface TTBoardView : UIView
@property (nonatomic, weak) id<TTBoardViewDelegate> delegate;
@property (nonatomic, strong) TTScene *scene;

- (void)reloadAll;       // mapa, grid e tokens
- (void)reloadGrid;      // grid e posição dos tokens (após mudar tamanho/deslocamento)
- (void)reloadTokens;    // recria todos os tokens
- (CGRect)rectForToken:(TTToken *)token;
- (CGPoint)cellForPoint:(CGPoint)point;   // x = coluna, y = linha
- (void)zoomDidChange;   // reajusta o tamanho dos textos da régua
@end
