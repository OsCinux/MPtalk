//
//  HPWelcomeViewController.m
//  MPTalk
//
//  Created by apple on 15/5/2.
//  Copyright (c) 2015年 2012110401. All rights reserved.
//

#import "HPWelcomeViewController.h"
#import "ProgressHUD.h"
#import "common.h"
#import "DRRRManager.h"
@interface HPWelcomeViewController ()<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextfield;

@end

@implementation HPWelcomeViewController
-(void)viewDidDisappear:(BOOL)animated
{
  //  [self removeObserver:self forKeyPath:DRRRMANAGER_AUTHENTICATE];
     [[NSNotificationCenter defaultCenter] removeObserver:self name:DRRRMANAGER_AUTHENTICATE object:nil];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //触摸一边键盘退去
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:gestureRecognizer];
    gestureRecognizer.cancelsTouchesInView = NO;
    
    self.nameTextField.delegate=self;
    self.passwordTextfield.delegate=self;
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onlineNotification:) name:DRRRMANAGER_AUTHENTICATE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backtodenglu) name:@"backtodenglu"object:nil];
}
-(void)backtodenglu{
//    [self presentViewController:self animated:YES completion:^{
//    }];
    [self.presentedViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
    
}
-(void)dismissKeyboard
{
    [self.view endEditing:YES];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
  [textField resignFirstResponder];
    return YES;
    
}

- (IBAction)loginAction:(id)sender {
    if ([self.nameTextField.text length]==0) {
        [ProgressHUD showError:@"请输入账号名"];
        return;
    }
    if ([self.passwordTextfield.text length]==0) {
        [ProgressHUD showError:@" 请输入密码"];
        return;
    }
    [ProgressHUD show:@"Signing in..." Interaction:NO];
    [[DRRRManager sharedManager]signinWithUsername:self.nameTextField.text password:self.passwordTextfield.text host:HOST_IP isregister:NO];//登录

    
}
#pragma mark - Notification
-(void)onlineNotification:(NSNotification*)notification{
    NSArray *result=(NSArray*)notification.object;
  //  BOOL online=[notification.object boolValue];
    if (result) {
        if ([result[0] boolValue]==YES){
            [ProgressHUD showSuccess:@"登录成功!"];
           [self performSegueWithIdentifier:@"logined" sender:self];
        }
        else
        {
               NSLog(@"%@",result[1]);
           [ProgressHUD showError:result[1]];
        }

    }
    }
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
