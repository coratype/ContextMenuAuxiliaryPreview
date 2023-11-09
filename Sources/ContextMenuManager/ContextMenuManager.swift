//
//  ContextMenuManager.swift
//  
//
//  Created by Dominic Go on 10/7/23.
//

import UIKit


public class ContextMenuManager {

  static weak var auxPreview: UIView?;
  
  // MARK: - Properties
  // ------------------
  
  public var menuAuxPreviewConfig: AuxiliaryPreviewConfig?;
  
  var auxPreviewManager: AuxiliaryPreviewMenuManager? {
    willSet {
      guard let newValue = newValue else { return };
      
      self.attachAndAnimateAuxiliaryPreviewUsingCustomAnimator(
        usingAuxiliaryPreviewManager: newValue
      );
    }
  };
  
  public var isAuxiliaryPreviewEnabled = true;
  public var isContextMenuVisible = false;
  
  public var menuAuxiliaryPreviewView: UIView?;
  
  var auxiliaryPreviewModalManager: AuxiliaryPreviewModalManager?;
  var auxiliaryPreviewModalVC: AuxiliaryPreviewModalViewController?;
  
  // MARK: - Properties - References
  // -------------------------------
  
  public weak var delegate: ContextMenuManagerDelegate?;
  
  /// A reference to the view that contains the context menu interaction
  public weak var menuTargetView: UIView?;
  
  /// A reference to the `UIContextMenuInteraction` interaction config that
  /// the `targetView` is using
  public weak var contextMenuInteraction: UIContextMenuInteraction?;
  
  /// A reference to the view controller that contains the custom context menu
  /// preview that will be used when the menu is shown
  public weak var menuCustomPreviewController: UIViewController?;
  
  // MARK: - Computed Properties
  // ---------------------------
  
  /// Gets the `_UIContextMenuContainerView` that's holding the context menu
  /// controls.
  ///
  /// **Note**: This `UIView` instance  only exists whenever there's a
  /// context menu interaction.
  ///
  var contextMenuContainerViewWrapper: ContextMenuContainerViewWrapper? {
    guard let targetView = self.menuTargetView,
          let window = targetView.window
    else { return nil };
    
    return window.subviews.reduce(nil) { (prev, subview) in
      prev ?? ContextMenuContainerViewWrapper(objectToWrap: subview);
    };
  };
  
  var isUsingCustomMenuPreview: Bool {
    self.menuCustomPreviewController != nil
  };

  public var isAuxiliaryPreviewVisible: Bool {
    self.auxPreviewManager?.isAuxPreviewVisible ?? false;
  };
  
  // MARK: - Init
  // ------------
  
  public init(
    contextMenuInteraction: UIContextMenuInteraction,
    menuTargetView: UIView
  ) {
    self.contextMenuInteraction = contextMenuInteraction;
    self.menuTargetView = menuTargetView;
  };
  
  // MARK: - Functions
  // -----------------
  
  func attachAndAnimateAuxiliaryPreviewUsingCustomAnimator(
    usingAuxiliaryPreviewManager manager: AuxiliaryPreviewMenuManager
  ){
    guard self.isAuxiliaryPreviewEnabled,
          self.menuAuxiliaryPreviewView != nil,
          self.menuAuxPreviewConfig != nil
    else { return };
    
    manager.attachAndAnimateInAuxiliaryPreviewUsingCustomAnimator();
  };
  
  // MARK: - Public Functions
  // ------------------------
  
  public func showAuxiliaryPreviewAsPopover(
    presentingViewController presentingVC: UIViewController
  ){
    guard !self.isContextMenuVisible,
          let menuAuxPreviewConfig = self.menuAuxPreviewConfig,
          let menuTargetView = self.menuTargetView,
          
          let delegate = self.delegate
    else { return };
    
    let auxPreviewView = delegate.onRequestMenuAuxiliaryPreview(sender: self);
    self.menuAuxiliaryPreviewView = auxPreviewView;
    
    let modalVC = AuxiliaryPreviewModalViewController();
    modalVC.view = auxPreviewView;
    
    self.auxiliaryPreviewModalVC = modalVC;
    
    let modalManager = AuxiliaryPreviewModalManager(
      menuAuxPreviewConfig: menuAuxPreviewConfig
    );
    
    self.auxiliaryPreviewModalManager = modalManager;
    
    modalManager.present(
      viewControllerToPresent: modalVC,
      presentingViewController: presentingVC,
      targetView: menuTargetView
    )
  };
  
  // context menu display begins
  public func notifyOnContextMenuInteraction(
    _ interaction: UIContextMenuInteraction,
    willDisplayMenuFor configuration: UIContextMenuConfiguration,
    animator: UIContextMenuInteractionAnimating?
  ) {
    
    guard self.isAuxiliaryPreviewEnabled,
          let menuAuxPreviewConfig = self.menuAuxPreviewConfig,
          let animator = animator,
          let delegate = self.delegate
    else { return };
    
    self.menuAuxiliaryPreviewView =
      delegate.onRequestMenuAuxiliaryPreview(sender: self);
      
    animator.addAnimations {
      let auxPreviewManager = AuxiliaryPreviewMenuManager(
        usingContextMenuManager: self,
        contextMenuAnimator: animator
      );
      
      guard let auxPreviewManager = auxPreviewManager else { return };
      self.auxPreviewManager = auxPreviewManager;
      
      auxPreviewManager.nudgeContextMenuIfNeeded();
      auxPreviewManager.notifyOnMenuWillShow();
      
      guard case .syncedToMenuEntranceTransition =
              menuAuxPreviewConfig.transitionConfigEntrance
      else { return };
      
      print(
        "notifyOnContextMenuInteraction",
        "- addAnimations block"
      );
      
      auxPreviewManager.debugPrintValues();
      auxPreviewManager.attachAndAnimateInAuxiliaryPreviewTogetherWithContextMenu();
    };
    
    animator.addCompletion {
      self.isContextMenuVisible = true;
      
      print(
        "notifyOnContextMenuInteraction",
        "- addCompletion block"
      );
      
      self.auxPreviewManager?.debugPrintValues();
    };
  };
  
  public func notifyOnContextMenuInteraction(
    _ interaction: UIContextMenuInteraction,
    willEndFor configuration: UIContextMenuConfiguration,
    animator: UIContextMenuInteractionAnimating?
  ) {
  
    guard self.isAuxiliaryPreviewEnabled,
          let animator = animator,
          let auxPreviewManager = self.auxPreviewManager
    else { return };
    
    auxPreviewManager.notifyOnMenuWillHide();
    
    animator.addAnimations {
      auxPreviewManager.detachAndAnimateOutAuxiliaryPreview();
    };
    
    animator.addCompletion {
      self.auxPreviewManager = nil;
      self.menuAuxiliaryPreviewView = nil;
    };
  };
};
