//
//  LoginController+handlers.swift
//  Facebook Messenger
//
//  Created by Amith Dubbasi on 2/6/18.
//  Copyright © 2018 iDiscover. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD

extension LoginViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    @objc func handleSelectProfilePicture()
    {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("Cancelled UIImagePickerController")
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerOrginalImage"] as? UIImage{
            
            selectedImageFromPicker = editedImage
        }
        else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            
            selectedImageFromPicker = originalImage
        }
        
        if let profileImage = selectedImageFromPicker{
            profileImageView.image = profileImage
        }
        
        dismiss(animated: true, completion: nil)
    }
    //Handle the user Registration to the Firebase cloud
    
    @objc func openCamera()
    {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera){
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.camera
            imagePicker.allowsEditing = true
            self.present(imagePicker,animated: true, completion : nil)
        }
    }
    func customAlert(title:String,message:String)
    {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(defaultAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    @objc func handleRegister()
    {
        guard let email = emailTextField.text, let password = passwordTextField.text, let name = nameTextField.text else {
            print("Empty email and Password")
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error) in
            
            if error != nil{
                SVProgressHUD.dismiss()
                self.customAlert(title: "Email already taken",message: "")
                self.emailTextField.text = "";
                self.passwordTextField.text = "";
                print(error!)
                return
            }
            print("Successfully Registered User")
            
            guard let uid = user?.uid else {
                print("User Not found")
                return
            }
            
            let imageName = UUID().uuidString
            let storageRef = Storage.storage().reference().child("profile_images").child("\(imageName).jpg")
            
            if let profileImage = self.profileImageView.image, let uploadData = UIImageJPEGRepresentation(profileImage, 0.1) {
                
                //upload image with unique name
                storageRef.putData(uploadData, metadata: nil, completion: { (metadata,error) in
                    
                    if(error != nil)
                    {
                        print(error!)
                        return
                        
                    }
                    if let profileImageUrl = metadata?.downloadURL()?.absoluteString {
                        
                        let values = ["name":name,"email":email,"profileImageUrl" : profileImageUrl]
                        self.registerUserIntoDatabaseWithUID(uid, values: values as [String : AnyObject])
                        
                    }
                    
                })
            }
            
        
        })
    }
    
    fileprivate func registerUserIntoDatabaseWithUID(_ uid: String, values: [String: AnyObject]) {
        let ref = Database.database().reference()
        let usersReference = ref.child("users").child(uid)
        
        usersReference.updateChildValues(values, withCompletionBlock: { (err, ref) in
            
            if err != nil {
                print(err!)
                return
            }
            let user = User(dictionary: values)
           self.messagesController?.setNavBarWithUser(user: user)
            SVProgressHUD.dismiss()
            self.dismiss(animated: true, completion: nil)
        })
    }

}


