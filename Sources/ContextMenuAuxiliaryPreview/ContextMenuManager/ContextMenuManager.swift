//
//  ContextMenuManager.swift
//  
//
//  Created by Dominic Go on 10/7/23.
//

import UIKit



struct AuxiliaryPreviewTransitionKeyframe {
  var opacity: CGFloat;
};

struct AuxiliaryPreviewTransitionConfig {
  var keyframeStart: AuxiliaryPreviewTransitionKeyframe;
  var keyframeEnd: AuxiliaryPreviewTransitionKeyframe;
};


class AuxiliaryRootView: UIView {

  override init(frame: CGRect) {
    super.init(frame: frame);
    
    self.backgroundColor = .red;
  };
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  };
};


public class ContextMenuManager {

  static weak var auxPreview: AuxiliaryRootView?;
  
  // MARK: - Properties
  // ------------------
  
  public var menuAuxPreviewConfig: ContextMenuAuxiliaryPreviewConfig?;
  var auxPreviewManager: ContextMenuAuxiliaryPreviewManager?;
  
  public var isAuxiliaryPreviewEnabled = true;
  
  public var isContextMenuVisible = false;
  public var isAuxPreviewVisible = false;
  
  // temp
  var menuAuxiliaryPreviewView: AuxiliaryRootView? {
    let view = AuxiliaryRootView(frame: .init(
      origin: .zero,
      size: .zero
    ));
    
    return view;
  };
  
  // MARK: - Properties - References
  // -------------------------------
  
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
  
  // MARK: - Init
  // ------------
  
  public init(
    contextMenuInteraction: UIContextMenuInteraction,
    menuTargetView: UIView
  ) {
    self.contextMenuInteraction = contextMenuInteraction;
    self.menuTargetView = menuTargetView;
  };
  
  // MARK: - Public Functions
  // ------------------------
  
  // context menu display begins
  public func notifyOnContextMenuInteraction(
    _ interaction: UIContextMenuInteraction,
    willDisplayMenuFor configuration: UIContextMenuConfiguration,
    animator: UIContextMenuInteractionAnimating?
  ) {
    
    guard self.isAuxiliaryPreviewEnabled,
          let animator = animator
    else { return };
    
    animator.addAnimations {
      let auxPreviewManager = ContextMenuAuxiliaryPreviewManager(
        usingContextMenuManager: self,
        contextMenuAnimator: animator
      );
      
      guard let auxPreviewManager = auxPreviewManager else { return };
      self.auxPreviewManager = auxPreviewManager;
      
      auxPreviewManager.attachAndAnimateInAuxiliaryPreview();
    };
    
    animator.addCompletion {
      self.isContextMenuVisible = true;
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
    
    
    animator.addAnimations {
      auxPreviewManager.detachAndAnimateOutAuxiliaryPreview();
    };
    
    animator.addCompletion {
      self.isAuxPreviewVisible = false;
      self.auxPreviewManager = nil;
    };
  };
};
