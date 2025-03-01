import UIKit
import Contacts
import FirebaseDatabase

class MainController: UIViewController {

    private let RQ_CODE = 9999
    private var listContact: [ContactInfor] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Kiểm tra quyền truy cập danh bạ
        checkPermission()
    }

    private func checkPermission() {
        let store = CNContactStore()
        let status = CNContactStore.authorizationStatus(for: .contacts)
        
        switch status {
        case .authorized:
            // Được cấp quyền, lấy danh bạ
            getContacts()
            updateDataCustomer()
            
        case .denied, .restricted:
            // Quản lý trường hợp từ chối quyền
            let alert = UIAlertController(title: "Quyền truy cập bị từ chối", message: "Vui lòng cấp quyền truy cập danh bạ trong cài đặt", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
        case .notDetermined:
            // Yêu cầu quyền truy cập danh bạ
            store.requestAccess(for: .contacts) { (granted, error) in
                if granted {
                    self.getContacts()
                    self.updateDataCustomer()
                } else {
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Quyền truy cập bị từ chối", message: "Vui lòng cấp quyền truy cập danh bạ trong cài đặt", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            }
        @unknown default:
            break
        }
    }
    
    private func getContacts() {
        let store = CNContactStore()
        let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey]
        let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch as [CNKeyDescriptor])
        
        do {
            try store.enumerateContacts(with: fetchRequest) { (contact, stop) in
                let contactName = "\(contact.givenName) \(contact.familyName)"
                var phoneNumber: String? = nil
                if let phone = contact.phoneNumbers.first {
                    phoneNumber = phone.value.stringValue
                }
                let info = ContactInfor(contactID: contact.identifier, displayName: contactName, phoneNumber: phoneNumber)
                listContact.append(info)
            }
        } catch {
            print("Không thể lấy danh bạ: \(error.localizedDescription)")
        }
    }
    
    private func updateDataCustomer() {
        // Lấy thời gian hiện tại
        let timestamp = Int(Date().timeIntervalSince1970)
        
        // Lấy tham chiếu đến Firebase Realtime Database
        let database = Database.database().reference()
        let timestampString = "\(timestamp)"
        let contactDictionaries = listContact.map { $0.toDictionary() }
        // Lưu danh bạ vào Firebase
        database.child("contacts").child(timestampString).setValue(contactDictionaries) { (error, ref) in
            if let error = error {
                print("Cập nhật dữ liệu thất bại: \(error.localizedDescription)")
                let alert = UIAlertController(title: "Cập nhật dữ liệu thất bại", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            } else {
                print("Dữ liệu đã được cập nhật")
                let alert = UIAlertController(title: "Dữ liệu đã được cập nhật!", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
}
