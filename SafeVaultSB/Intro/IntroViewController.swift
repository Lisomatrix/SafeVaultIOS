//
//  IntroViewController.swift
//  SafeVaultSB
//
//  Created by Tiago Lima on 07/07/2020.
//  Copyright © 2020 Tiago Lima. All rights reserved.
//

import UIKit

class IntroViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    var pageIndex = 0
    
    private lazy var slideViewControllers: [UIViewController] = {
        return [
            self.newViewController(name: "welcomeOne"),
            self.newViewController(name: "welcomeTwo"),
            self.newViewController(name: "warningOne"),
            self.newViewController(name: "warningTwo")
        ]
    }()

    
    private func newViewController(name: String) -> UIViewController {
        return UIStoryboard(name: "Main", bundle: nil) .
            instantiateViewController(withIdentifier: name)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.dataSource = self;
        
        self.setViewControllers([self.slideViewControllers[0]], direction: UIPageViewController.NavigationDirection.forward, animated: true, completion: nil)
        
        let isDarkTheme = traitCollection.userInterfaceStyle == .dark
        
        let appearance = UIPageControl.appearance(whenContainedInInstancesOf: [UIPageViewController.self])
        
        if isDarkTheme {
            appearance.backgroundColor = UIColor.black
        } else {
            appearance.backgroundColor = mainBlue
        }
        
        appearance.pageIndicatorTintColor = UIColor.lightGray
        appearance.currentPageIndicatorTintColor = UIColor.white
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return self.slideViewControllers.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return self.pageIndex
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = self.slideViewControllers.firstIndex(of: viewController) else {
            return nil
        }
          
        let nextIndex = viewControllerIndex + 1
        let slideViewControllerCount = self.slideViewControllers.count

        guard slideViewControllerCount != nextIndex else {
            return nil
        }
          
        guard slideViewControllerCount > nextIndex else {
            return nil
        }
          
        pageIndex = nextIndex
        
        return self.slideViewControllers[nextIndex]
    }
      
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
          
        guard let viewControllerIndex = self.slideViewControllers.firstIndex(of: viewController) else {
            return nil
        }
               
        let previousIndex = viewControllerIndex - 1
               
        guard previousIndex >= 0 else {
            return nil
        }
               
        guard self.slideViewControllers.count > previousIndex else {
            return nil
        }
         
        pageIndex = previousIndex
        
        return self.slideViewControllers[previousIndex]
    }
}
