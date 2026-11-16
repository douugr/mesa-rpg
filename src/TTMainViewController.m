#import "TTMainViewController.h"
#import "TTModel.h"
#import "TTBoardView.h"
#import <QuartzCore/QuartzCore.h>

static const CGFloat kTTToolbarHeight = 56;
static const CGFloat kTTInitiativeWidth = 300;

@interface TTMainViewController () <UIScrollViewDelegate, TTBoardViewDelegate,
                                    UITableViewDataSource, UITableViewDelegate,
                                    UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (nonatomic, strong) TTStore *store;

@property (nonatomic, strong) UIView *toolbar;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *scenesButton;
@property (nonatomic, strong) UIButton *mapButton;
@property (nonatomic, strong) UIButton *gridButton;
@property (nonatomic, strong) UIButton *addTokenButton;
@property (nonatomic, strong) UIButton *initiativeButton;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) TTBoardView *board;
@property (nonatomic, assign) BOOL needsFit;

@property (nonatomic, strong) UIView *gridPanel;
@property (nonatomic, strong) UISlider *cellSlider;
@property (nonatomic, strong) UISlider *offsetXSlider;
@property (nonatomic, strong) UISlider *offsetYSlider;
@property (nonatomic, strong) UISlider *alphaSlider;
@property (nonatomic, strong) UISwitch *gridSwitch;
@property (nonatomic, strong) UIStepper *metersStepper;
@property (nonatomic, strong) UILabel *cellValueLabel;
@property (nonatomic, strong) UILabel *metersValueLabel;

@property (nonatomic, strong) UIView *initiativePanel;
@property (nonatomic, strong) UITableView *initiativeTable;
@property (nonatomic, strong) UILabel *roundLabel;
@property (nonatomic, strong) UIButton *nextTurnButton;
@property (nonatomic, strong) UIButton *reorderButton;
@end

@implementation TTMainViewController

#pragma mark - Setup

- (UIButton *)toolbarButton:(NSString *)title action:(SEL)action {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    [b setTitle:title forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    [b setTitleColor:[UIColor colorWithRed:1 green:0.85 blue:0.2 alpha:1] forState:UIControlStateNormal];
    [b addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [self.toolbar addSubview:b];
    return b;
}

- (UILabel *)panelLabel:(NSString *)text {
    UILabel *l = [[UILabel alloc] init];
    l.text = text;
    l.textColor = [UIColor colorWithWhite:0.85 alpha:1];
    l.font = [UIFont systemFontOfSize:15];
    l.adjustsFontSizeToFitWidth = YES;
    l.minimumScaleFactor = 0.6;
    return l;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.store = [TTStore load];

    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.delegate = self;
    self.scrollView.backgroundColor = [UIColor colorWithWhite:0.05 alpha:1];
    self.scrollView.panGestureRecognizer.minimumNumberOfTouches = 2;  // 1 dedo = tokens e régua
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.bouncesZoom = YES;
    [self.view addSubview:self.scrollView];

    self.board = [[TTBoardView alloc] initWithFrame:CGRectZero];
    self.board.delegate = self;
    [self.scrollView addSubview:self.board];

    self.toolbar = [[UIView alloc] init];
    self.toolbar.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.96];
    [self.view addSubview:self.toolbar];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.titleLabel.minimumScaleFactor = 0.6;
    [self.toolbar addSubview:self.titleLabel];

    self.scenesButton = [self toolbarButton:@"Cenas" action:@selector(scenesTapped)];
    self.mapButton = [self toolbarButton:@"Mapa" action:@selector(mapTapped)];
    self.gridButton = [self toolbarButton:@"Grid" action:@selector(gridTapped)];
    self.addTokenButton = [self toolbarButton:@"+ Token" action:@selector(addTokenTapped)];
    self.initiativeButton = [self toolbarButton:@"Iniciativa" action:@selector(initiativeTapped)];

    [self buildGridPanel];
    [self buildInitiativePanel];
    [self loadCurrentScene];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat W = self.view.bounds.size.width, H = self.view.bounds.size.height;

    self.toolbar.frame = CGRectMake(0, 0, W, kTTToolbarHeight);
    CGFloat bw = 92;
    self.scenesButton.frame = CGRectMake(8, 0, bw - 16, kTTToolbarHeight);
    self.mapButton.frame = CGRectMake(bw, 0, bw - 16, kTTToolbarHeight);
    self.gridButton.frame = CGRectMake(2 * bw - 8, 0, bw - 16, kTTToolbarHeight);
    self.initiativeButton.frame = CGRectMake(W - 110, 0, 102, kTTToolbarHeight);
    self.addTokenButton.frame = CGRectMake(W - 210, 0, 96, kTTToolbarHeight);
    CGFloat titleX = 3 * bw - 8;
    self.titleLabel.frame = CGRectMake(titleX, 0, (W - 220) - titleX, kTTToolbarHeight);

    CGRect old = self.scrollView.frame;
    self.scrollView.frame = CGRectMake(0, kTTToolbarHeight, W, H - kTTToolbarHeight);
    if (!CGSizeEqualToSize(old.size, self.scrollView.frame.size)) {
        self.needsFit = YES;
    }
    if (self.needsFit) {
        [self fitBoard];
    }

    CGFloat gpH = 300;
    CGFloat gpW = MIN(W - 20, 520);
    self.gridPanel.frame = CGRectMake((W - gpW) / 2.0, H - gpH - 10, gpW, gpH);
    [self layoutGridPanel];

    self.initiativePanel.frame = CGRectMake(W - kTTInitiativeWidth, kTTToolbarHeight, kTTInitiativeWidth, H - kTTToolbarHeight);
    [self layoutInitiativePanel];
}

#pragma mark - Scene / board

- (TTScene *)scene {
    return [self.store currentScene];
}

- (void)loadCurrentScene {
    self.titleLabel.text = self.scene.name;
    self.board.scene = self.scene;
    self.scrollView.zoomScale = 1;
    [self.board reloadAll];
    self.board.frame = CGRectMake(0, 0, self.scene.boardWidth, self.scene.boardHeight);
    self.scrollView.contentSize = self.board.frame.size;
    self.needsFit = YES;
    [self.view setNeedsLayout];
    [self syncGridPanel];
    [self.initiativeTable reloadData];
    [self updateRoundLabel];
}

- (void)fitBoard {
    CGSize vs = self.scrollView.bounds.size;
    if (vs.width < 1 || vs.height < 1) return;
    CGFloat fit = MIN(vs.width / self.scene.boardWidth, vs.height / self.scene.boardHeight);
    self.scrollView.minimumZoomScale = fit;
    self.scrollView.maximumZoomScale = MAX(fit * 6, 2);
    self.scrollView.zoomScale = fit;
    self.needsFit = NO;
    [self centerBoard];
}

- (void)centerBoard {
    CGSize vs = self.scrollView.bounds.size;
    CGSize cs = self.scrollView.contentSize;
    CGFloat ix = MAX(0, (vs.width - cs.width) / 2.0);
    CGFloat iy = MAX(0, (vs.height - cs.height) / 2.0);
    self.scrollView.contentInset = UIEdgeInsetsMake(iy, ix, iy, ix);
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.board;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self centerBoard];
    [self.board zoomDidChange];
}

- (void)saveAndRefresh {
    [self.store save];
    [self.initiativeTable reloadData];
    [self updateRoundLabel];
}

#pragma mark - TTBoardViewDelegate

- (CGFloat)zoomScaleForBoard:(TTBoardView *)board {
    return self.scrollView.zoomScale;
}

- (void)boardDidChange:(TTBoardView *)board {
    [self saveAndRefresh];
}

- (void)board:(TTBoardView *)board didTapToken:(TTToken *)token {
    [self editToken:token];
}

#pragma mark - Presentation helpers

- (void)presentSheet:(UIAlertController *)sheet from:(UIView *)source {
    sheet.popoverPresentationController.sourceView = source;
    sheet.popoverPresentationController.sourceRect = source.bounds;
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)showMessage:(NSString *)title text:(NSString *)text {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:title message:text preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)askForText:(NSString *)title initial:(NSString *)initial completion:(void (^)(NSString *text))completion {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    [a addTextFieldWithConfigurationHandler:^(UITextField *f) {
        f.text = initial;
        f.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        f.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    __weak UIAlertController *weakA = a;
    [a addAction:[UIAlertAction actionWithTitle:@"Cancelar" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
        NSString *text = [weakA.textFields.firstObject.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (text.length) completion(text);
    }]];
    [self presentViewController:a animated:YES completion:nil];
}

#pragma mark - Cenas

- (void)scenesTapped {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Cenas" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSInteger i = 0; i < (NSInteger)self.store.scenes.count; i++) {
        TTScene *s = self.store.scenes[i];
        NSString *title = (i == self.store.currentIndex) ? [NSString stringWithFormat:@"%@ ✓", s.name] : s.name;
        [sheet addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            self.store.currentIndex = i;
            [self.store save];
            [self loadCurrentScene];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"Nova cena…" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        NSString *suggestion = [NSString stringWithFormat:@"Cena %lu", (unsigned long)self.store.scenes.count + 1];
        [self askForText:@"Nome da nova cena" initial:suggestion completion:^(NSString *text) {
            [self.store addSceneNamed:text];
            [self loadCurrentScene];
        }];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Renomear cena atual…" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [self askForText:@"Nome da cena" initial:self.scene.name completion:^(NSString *text) {
            self.scene.name = text;
            self.titleLabel.text = text;
            [self.store save];
        }];
    }]];
    if (self.store.scenes.count > 1) {
        [sheet addAction:[UIAlertAction actionWithTitle:@"Apagar cena atual" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
            [self confirmDeleteScene];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancelar" style:UIAlertActionStyleCancel handler:nil]];
    [self presentSheet:sheet from:self.scenesButton];
}

- (void)confirmDeleteScene {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Apagar \"%@\"?", self.scene.name]
                                                               message:@"O mapa e os tokens desta cena serão apagados."
                                                        preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Cancelar" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"Apagar" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *act) {
        [self.store removeCurrentScene];
        [self loadCurrentScene];
    }]];
    [self presentViewController:a animated:YES completion:nil];
}

#pragma mark - Mapa

- (void)mapTapped {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Mapa da cena" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Escolher das Fotos" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [self pickFromPhotos];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Arquivos do app (Finder / SSH)" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [self pickFromDocuments];
    }]];
    if (self.scene.imageFile) {
        [sheet addAction:[UIAlertAction actionWithTitle:@"Remover mapa" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
            [self.store removeMapForScene:self.scene];
            [self.store save];
            [self loadCurrentScene];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancelar" style:UIAlertActionStyleCancel handler:nil]];
    [self presentSheet:sheet from:self.mapButton];
}

- (void)pickFromPhotos {
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        [self showMessage:@"Fotos indisponíveis" text:@"Não foi possível acessar a biblioteca de fotos."];
        return;
    }
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    picker.modalPresentationStyle = UIModalPresentationPopover;
    picker.popoverPresentationController.sourceView = self.mapButton;
    picker.popoverPresentationController.sourceRect = self.mapButton.bounds;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:^{
        [self applyMapImage:image];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)applyMapImage:(UIImage *)image {
    if (!image) {
        [self showMessage:@"Erro" text:@"Não foi possível abrir a imagem."];
        return;
    }
    [self.store setMapImage:image forScene:self.scene];
    [self loadCurrentScene];
}

- (void)pickFromDocuments {
    NSString *docs = [TTStore documentsPath];
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:docs error:nil];
    NSMutableArray *images = [NSMutableArray array];
    for (NSString *f in [files sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]) {
        NSString *ext = f.pathExtension.lowercaseString;
        if ([ext isEqualToString:@"jpg"] || [ext isEqualToString:@"jpeg"] || [ext isEqualToString:@"png"]) {
            [images addObject:f];
        }
    }
    if (images.count == 0) {
        [self showMessage:@"Nenhuma imagem encontrada"
                     text:@"Copie mapas (JPG ou PNG) para a pasta Documentos do app \"Mesa RPG\", pelo Finder (aba Arquivos do iPad) ou via SSH."];
        return;
    }
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Arquivos do app" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSString *f in images) {
        [sheet addAction:[UIAlertAction actionWithTitle:f style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            UIImage *image = [UIImage imageWithContentsOfFile:[docs stringByAppendingPathComponent:f]];
            [self applyMapImage:image];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancelar" style:UIAlertActionStyleCancel handler:nil]];
    [self presentSheet:sheet from:self.mapButton];
}

#pragma mark - Grid

- (UISlider *)gridSliderWithAction:(SEL)action {
    UISlider *s = [[UISlider alloc] init];
    s.minimumTrackTintColor = [UIColor colorWithRed:1 green:0.85 blue:0.2 alpha:1];
    [s addTarget:self action:action forControlEvents:UIControlEventValueChanged];
    [s addTarget:self action:@selector(gridEditingEnded) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    [self.gridPanel addSubview:s];
    return s;
}

- (UIButton *)gridSmallButton:(NSString *)title tag:(NSInteger)tag {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    [b setTitle:title forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont boldSystemFontOfSize:22];
    [b setTitleColor:[UIColor colorWithRed:1 green:0.85 blue:0.2 alpha:1] forState:UIControlStateNormal];
    b.tag = tag;
    [b addTarget:self action:@selector(gridNudge:) forControlEvents:UIControlEventTouchUpInside];
    [self.gridPanel addSubview:b];
    return b;
}

- (void)buildGridPanel {
    self.gridPanel = [[UIView alloc] init];
    self.gridPanel.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.95];
    self.gridPanel.layer.cornerRadius = 14;
    self.gridPanel.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.2].CGColor;
    self.gridPanel.layer.borderWidth = 1;
    self.gridPanel.hidden = YES;
    [self.view addSubview:self.gridPanel];

    NSArray *titles = @[@"Tamanho do quadrado", @"Deslocar na horizontal", @"Deslocar na vertical", @"Opacidade", @"Mostrar grid", @"Metros por quadrado"];
    for (NSInteger i = 0; i < (NSInteger)titles.count; i++) {
        UILabel *l = [self panelLabel:titles[i]];
        l.tag = 100 + i;
        [self.gridPanel addSubview:l];
    }

    self.cellSlider = [self gridSliderWithAction:@selector(gridSliderChanged)];
    self.offsetXSlider = [self gridSliderWithAction:@selector(gridSliderChanged)];
    self.offsetYSlider = [self gridSliderWithAction:@selector(gridSliderChanged)];
    self.alphaSlider = [self gridSliderWithAction:@selector(gridSliderChanged)];
    self.alphaSlider.minimumValue = 0.1;
    self.alphaSlider.maximumValue = 1.0;

    [self gridSmallButton:@"−" tag:1];
    [self gridSmallButton:@"+" tag:2];

    self.cellValueLabel = [self panelLabel:@""];
    self.cellValueLabel.textAlignment = NSTextAlignmentRight;
    [self.gridPanel addSubview:self.cellValueLabel];

    self.gridSwitch = [[UISwitch alloc] init];
    [self.gridSwitch addTarget:self action:@selector(gridSwitchChanged) forControlEvents:UIControlEventValueChanged];
    [self.gridPanel addSubview:self.gridSwitch];

    self.metersStepper = [[UIStepper alloc] init];
    self.metersStepper.minimumValue = 0.5;
    self.metersStepper.maximumValue = 10;
    self.metersStepper.stepValue = 0.5;
    self.metersStepper.tintColor = [UIColor colorWithRed:1 green:0.85 blue:0.2 alpha:1];
    [self.metersStepper addTarget:self action:@selector(metersChanged) forControlEvents:UIControlEventValueChanged];
    [self.gridPanel addSubview:self.metersStepper];

    self.metersValueLabel = [self panelLabel:@""];
    [self.gridPanel addSubview:self.metersValueLabel];

    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    [close setTitle:@"Fechar" forState:UIControlStateNormal];
    close.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    [close setTitleColor:[UIColor colorWithRed:1 green:0.85 blue:0.2 alpha:1] forState:UIControlStateNormal];
    close.tag = 99;
    [close addTarget:self action:@selector(gridTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.gridPanel addSubview:close];
}

- (void)layoutGridPanel {
    CGFloat w = self.gridPanel.bounds.size.width;
    CGFloat pad = 16, rowH = 44, y = 12;
    CGFloat labelW = 190;
    CGFloat ctrlX = pad + labelW;
    CGFloat ctrlW = w - ctrlX - pad;

    // Linha 1: tamanho, com botões de ajuste fino
    [self.gridPanel viewWithTag:100].frame = CGRectMake(pad, y, labelW, rowH / 2);
    self.cellValueLabel.frame = CGRectMake(ctrlX, y, ctrlW, rowH / 2);
    y += rowH / 2;
    [self.gridPanel viewWithTag:1].frame = CGRectMake(pad, y, 40, rowH);
    [self.gridPanel viewWithTag:2].frame = CGRectMake(w - pad - 40, y, 40, rowH);
    self.cellSlider.frame = CGRectMake(pad + 48, y, w - 2 * pad - 96, rowH);
    y += rowH;

    NSArray *sliders = @[self.offsetXSlider, self.offsetYSlider, self.alphaSlider];
    for (NSInteger i = 0; i < 3; i++) {
        [self.gridPanel viewWithTag:101 + i].frame = CGRectMake(pad, y, labelW, rowH);
        [sliders[i] setFrame:CGRectMake(ctrlX, y, ctrlW, rowH)];
        y += rowH;
    }

    [self.gridPanel viewWithTag:104].frame = CGRectMake(pad, y, labelW, rowH);
    CGSize sw = self.gridSwitch.bounds.size;
    self.gridSwitch.frame = CGRectMake(ctrlX, y + (rowH - sw.height) / 2, sw.width, sw.height);
    [self.gridPanel viewWithTag:99].frame = CGRectMake(w - pad - 90, y, 90, rowH);
    y += rowH;

    [self.gridPanel viewWithTag:105].frame = CGRectMake(pad, y, labelW, rowH);
    CGSize st = self.metersStepper.bounds.size;
    self.metersStepper.frame = CGRectMake(ctrlX, y + (rowH - st.height) / 2, st.width, st.height);
    self.metersValueLabel.frame = CGRectMake(ctrlX + st.width + 12, y, 120, rowH);
}

- (void)syncGridPanel {
    TTScene *s = self.scene;
    CGFloat maxCell = MAX(40, MIN(s.boardWidth, s.boardHeight) / 3.0);
    self.cellSlider.minimumValue = 12;
    self.cellSlider.maximumValue = maxCell;
    self.cellSlider.value = s.cellSize;
    self.offsetXSlider.minimumValue = 0;
    self.offsetXSlider.maximumValue = s.cellSize;
    self.offsetXSlider.value = s.offsetX;
    self.offsetYSlider.minimumValue = 0;
    self.offsetYSlider.maximumValue = s.cellSize;
    self.offsetYSlider.value = s.offsetY;
    self.alphaSlider.value = s.gridAlpha;
    self.gridSwitch.on = s.gridVisible;
    self.metersStepper.value = s.metersPerCell;
    [self updateGridLabels];
}

- (void)updateGridLabels {
    TTScene *s = self.scene;
    NSInteger cols = (NSInteger)floor(s.boardWidth / MAX(1, s.cellSize));
    NSInteger rows = (NSInteger)floor(s.boardHeight / MAX(1, s.cellSize));
    self.cellValueLabel.text = [NSString stringWithFormat:@"%.1f px · %ld × %ld quadrados", s.cellSize, (long)cols, (long)rows];
    self.metersValueLabel.text = [NSString stringWithFormat:@"%g m", s.metersPerCell];
}

- (void)gridTapped {
    BOOL show = self.gridPanel.hidden;
    self.gridPanel.hidden = !show;
    if (show) {
        self.initiativePanel.hidden = YES;
        [self syncGridPanel];
        [self.view bringSubviewToFront:self.gridPanel];
    } else {
        [self.store save];
    }
}

- (void)gridSliderChanged {
    TTScene *s = self.scene;
    s.cellSize = self.cellSlider.value;
    self.offsetXSlider.maximumValue = s.cellSize;
    self.offsetYSlider.maximumValue = s.cellSize;
    s.offsetX = MIN(self.offsetXSlider.value, s.cellSize);
    s.offsetY = MIN(self.offsetYSlider.value, s.cellSize);
    s.gridAlpha = self.alphaSlider.value;
    [self.board reloadGrid];
    [self updateGridLabels];
}

- (void)gridNudge:(UIButton *)b {
    TTScene *s = self.scene;
    s.cellSize = MAX(12, s.cellSize + (b.tag == 2 ? 0.5 : -0.5));
    [self.board reloadGrid];
    [self syncGridPanel];
    [self.store save];
}

- (void)gridEditingEnded {
    [self.store save];
}

- (void)gridSwitchChanged {
    self.scene.gridVisible = self.gridSwitch.on;
    [self.board reloadGrid];
    [self.store save];
}

- (void)metersChanged {
    self.scene.metersPerCell = self.metersStepper.value;
    [self updateGridLabels];
    [self.store save];
}

#pragma mark - Tokens

- (void)addTokenTapped {
    TTScene *s = self.scene;
    CGPoint visibleCenter = CGPointMake(CGRectGetMidX(self.scrollView.bounds), CGRectGetMidY(self.scrollView.bounds));
    CGPoint boardPoint = [self.scrollView convertPoint:visibleCenter toView:self.board];
    CGPoint cell = [self.board cellForPoint:boardPoint];

    TTToken *t = [[TTToken alloc] init];
    NSUInteger n = s.tokens.count + 1;
    t.name = [NSString stringWithFormat:@"Token %lu", (unsigned long)n];
    t.label = [NSString stringWithFormat:@"%lu", (unsigned long)n];
    t.colorIndex = s.tokens.count % TTTokenColorCount();
    t.col = MAX(0, (NSInteger)cell.x);
    t.row = MAX(0, (NSInteger)cell.y);
    [s.tokens addObject:t];
    [self.board reloadTokens];
    [self saveAndRefresh];
    [self editToken:t];
}

- (void)editToken:(TTToken *)t {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:t.name
                                                               message:@"Rótulo: até 3 letras no círculo. PV máximo 0 esconde os PV."
                                                        preferredStyle:UIAlertControllerStyleAlert];
    [a addTextFieldWithConfigurationHandler:^(UITextField *f) {
        f.placeholder = @"Nome";
        f.text = t.name;
        f.autocapitalizationType = UITextAutocapitalizationTypeWords;
    }];
    [a addTextFieldWithConfigurationHandler:^(UITextField *f) {
        f.placeholder = @"Rótulo (ex.: V, G1)";
        f.text = t.label;
        f.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
    }];
    [a addTextFieldWithConfigurationHandler:^(UITextField *f) {
        f.placeholder = @"PV atual";
        f.text = t.maxHp > 0 ? [NSString stringWithFormat:@"%ld", (long)t.hp] : @"";
        f.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    }];
    [a addTextFieldWithConfigurationHandler:^(UITextField *f) {
        f.placeholder = @"PV máximo";
        f.text = t.maxHp > 0 ? [NSString stringWithFormat:@"%ld", (long)t.maxHp] : @"";
        f.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    }];

    __weak UIAlertController *weakA = a;
    void (^apply)(void) = ^{
        NSArray *fields = weakA.textFields;
        NSString *name = [[fields[0] text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (name.length) t.name = name;
        NSString *label = [[fields[1] text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        t.label = label.length > 3 ? [label substringToIndex:3] : label;
        t.maxHp = MAX(0, [[fields[3] text] integerValue]);
        NSString *hpText = [fields[2] text];
        t.hp = hpText.length ? [hpText integerValue] : t.maxHp;
    };

    [a addAction:[UIAlertAction actionWithTitle:@"Salvar" style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
        apply();
        [self tokensChanged];
    }]];
    [a addAction:[UIAlertAction actionWithTitle:@"Salvar e trocar cor" style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
        apply();
        t.colorIndex = (t.colorIndex + 1) % TTTokenColorCount();
        [self tokensChanged];
    }]];
    NSString *sizeTitle = [NSString stringWithFormat:@"Tamanho: %ld×%ld → %ld×%ld", (long)t.size, (long)t.size,
                           (long)(t.size % 3 + 1), (long)(t.size % 3 + 1)];
    [a addAction:[UIAlertAction actionWithTitle:sizeTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
        apply();
        t.size = t.size % 3 + 1;
        [self tokensChanged];
    }]];
    [a addAction:[UIAlertAction actionWithTitle:(t.down ? @"Levantar" : @"Marcar como caído") style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
        apply();
        t.down = !t.down;
        [self tokensChanged];
    }]];
    [a addAction:[UIAlertAction actionWithTitle:@"Duplicar" style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
        apply();
        TTToken *copy = [t duplicate];
        copy.col = t.col + t.size;
        [self.scene.tokens addObject:copy];
        [self tokensChanged];
    }]];
    [a addAction:[UIAlertAction actionWithTitle:@"Remover" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *act) {
        [self removeToken:t];
    }]];
    [a addAction:[UIAlertAction actionWithTitle:@"Cancelar" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)removeToken:(TTToken *)t {
    TTScene *s = self.scene;
    NSUInteger idx = [s.tokens indexOfObject:t];
    if (idx == NSNotFound) return;
    [s.tokens removeObjectAtIndex:idx];
    if (s.turnIndex >= (NSInteger)s.tokens.count) {
        s.turnIndex = s.tokens.count ? 0 : -1;
    } else if ((NSInteger)idx < s.turnIndex) {
        s.turnIndex--;
    }
    [self tokensChanged];
}

- (void)tokensChanged {
    [self.board reloadTokens];
    [self saveAndRefresh];
}

#pragma mark - Iniciativa

- (UIButton *)panelButton:(NSString *)title action:(SEL)action {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    [b setTitle:title forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [b setTitleColor:[UIColor colorWithRed:1 green:0.85 blue:0.2 alpha:1] forState:UIControlStateNormal];
    [b addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [self.initiativePanel addSubview:b];
    return b;
}

- (void)buildInitiativePanel {
    self.initiativePanel = [[UIView alloc] init];
    self.initiativePanel.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.96];
    self.initiativePanel.hidden = YES;
    [self.view addSubview:self.initiativePanel];

    self.roundLabel = [[UILabel alloc] init];
    self.roundLabel.textColor = [UIColor whiteColor];
    self.roundLabel.font = [UIFont boldSystemFontOfSize:17];
    [self.initiativePanel addSubview:self.roundLabel];

    self.nextTurnButton = [self panelButton:@"Iniciar" action:@selector(nextTurn)];
    self.reorderButton = [self panelButton:@"Ordenar" action:@selector(toggleReorder)];
    UIButton *end = [self panelButton:@"Encerrar" action:@selector(endCombat)];
    end.tag = 77;

    self.initiativeTable = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.initiativeTable.dataSource = self;
    self.initiativeTable.delegate = self;
    self.initiativeTable.backgroundColor = [UIColor clearColor];
    self.initiativeTable.separatorColor = [UIColor colorWithWhite:1 alpha:0.12];
    self.initiativeTable.rowHeight = 56;
    [self.initiativePanel addSubview:self.initiativeTable];
}

- (void)layoutInitiativePanel {
    CGFloat w = self.initiativePanel.bounds.size.width;
    CGFloat h = self.initiativePanel.bounds.size.height;
    self.roundLabel.frame = CGRectMake(14, 6, w - 28, 34);
    CGFloat bw = (w - 20) / 3.0;
    self.nextTurnButton.frame = CGRectMake(10, 42, bw, 40);
    self.reorderButton.frame = CGRectMake(10 + bw, 42, bw, 40);
    [self.initiativePanel viewWithTag:77].frame = CGRectMake(10 + 2 * bw, 42, bw, 40);
    self.initiativeTable.frame = CGRectMake(0, 88, w, h - 88);
}

- (void)initiativeTapped {
    BOOL show = self.initiativePanel.hidden;
    self.initiativePanel.hidden = !show;
    if (show) {
        self.gridPanel.hidden = YES;
        [self.initiativeTable reloadData];
        [self updateRoundLabel];
        [self.view bringSubviewToFront:self.initiativePanel];
    } else if (self.initiativeTable.editing) {
        [self toggleReorder];
    }
}

- (void)updateRoundLabel {
    TTScene *s = self.scene;
    if (s.turnIndex < 0) {
        self.roundLabel.text = @"Fora de combate";
        [self.nextTurnButton setTitle:@"Iniciar" forState:UIControlStateNormal];
    } else {
        self.roundLabel.text = [NSString stringWithFormat:@"Rodada %ld", (long)s.round];
        [self.nextTurnButton setTitle:@"Próximo" forState:UIControlStateNormal];
    }
}

- (void)nextTurn {
    TTScene *s = self.scene;
    NSInteger n = s.tokens.count;
    if (n == 0) return;
    if (s.turnIndex < 0) {
        s.round = 1;
        s.turnIndex = -1;
    }
    // Avança pulando quem está caído
    for (NSInteger step = 0; step < n; step++) {
        s.turnIndex++;
        if (s.turnIndex >= n) {
            s.turnIndex = 0;
            s.round++;
        }
        TTToken *t = s.tokens[s.turnIndex];
        if (!t.down) break;
    }
    [self tokensChanged];
    [self scrollToToken:s.tokens[s.turnIndex]];
}

- (void)endCombat {
    self.scene.turnIndex = -1;
    self.scene.round = 1;
    [self tokensChanged];
}

- (void)toggleReorder {
    BOOL editing = !self.initiativeTable.editing;
    [self.initiativeTable setEditing:editing animated:YES];
    [self.reorderButton setTitle:(editing ? @"Pronto" : @"Ordenar") forState:UIControlStateNormal];
}

- (void)scrollToToken:(TTToken *)t {
    CGRect r = [self.board rectForToken:t];
    CGRect inScroll = [self.board convertRect:CGRectInset(r, -r.size.width * 2, -r.size.height * 2) toView:self.scrollView];
    [self.scrollView scrollRectToVisible:inScroll animated:YES];
}

- (UIImage *)dotImageWithColor:(UIColor *)color {
    CGSize size = CGSizeMake(22, 22);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [color setFill];
    [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(1, 1, 20, 20)] fill];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.scene.tokens.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"token"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"token"];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:17];
        cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.7 alpha:1];
        cell.selectedBackgroundView = [[UIView alloc] init];
        cell.selectedBackgroundView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];
    }
    TTScene *s = self.scene;
    TTToken *t = s.tokens[indexPath.row];
    BOOL active = (indexPath.row == s.turnIndex);
    cell.textLabel.text = [NSString stringWithFormat:@"%@%@", active ? @"▶ " : @"", t.name];
    NSMutableArray *details = [NSMutableArray array];
    if (t.maxHp > 0) [details addObject:[NSString stringWithFormat:@"PV %ld/%ld", (long)t.hp, (long)t.maxHp]];
    if (t.down) [details addObject:@"caído"];
    cell.detailTextLabel.text = details.count ? [details componentsJoinedByString:@" · "] : @" ";
    cell.imageView.image = [self dotImageWithColor:TTTokenColor(t.colorIndex)];
    cell.backgroundColor = active ? [UIColor colorWithRed:0.35 green:0.3 blue:0.05 alpha:1] : [UIColor clearColor];
    cell.textLabel.alpha = t.down ? 0.5 : 1.0;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self scrollToToken:self.scene.tokens[indexPath.row]];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)from toIndexPath:(NSIndexPath *)to {
    TTScene *s = self.scene;
    TTToken *current = (s.turnIndex >= 0 && s.turnIndex < (NSInteger)s.tokens.count) ? s.tokens[s.turnIndex] : nil;
    TTToken *moved = s.tokens[from.row];
    [s.tokens removeObjectAtIndex:from.row];
    [s.tokens insertObject:moved atIndex:to.row];
    if (current) {
        s.turnIndex = [s.tokens indexOfObject:current];
    }
    [self.board reloadTokens];
    [self.store save];
    dispatch_async(dispatch_get_main_queue(), ^{
        [tableView reloadData];
    });
}

@end
