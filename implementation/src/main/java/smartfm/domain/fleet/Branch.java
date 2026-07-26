package smartfm.domain.fleet;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import smartfm.common.Validators;

/**
 * A regional operational hub of ABC-Trans that manages its own local
 * pool of vehicles, drivers, and staff. Corresponds to the {@code
 * Branch} CRC card in Assignment 2 Section 3 (Fleet and Resources
 * Package). Acts as the aggregation root for local resources.
 */
@SuppressWarnings("serial")
public class Branch implements Serializable {

  private static final long serialVersionUID = 1L;

  private final String id;
  private String name;
  private String city;
  private String contactPhone;
  private final List<String> vehicleIds = new ArrayList<>();
  private final List<String> driverIds = new ArrayList<>();
  private final List<String> staffIds = new ArrayList<>();
  private final List<String> serviceOfferingIds = new ArrayList<>();

  public Branch(String id, String name, String city, String contactPhone) {
    this.id = Validators.requireNonBlank(id, "Id", 20);
    this.name = Validators.requireNonBlank(name, "Branch name", 60);
    this.city = Validators.requireNonBlank(city, "City", 60);
    this.contactPhone = Validators.requirePhone(contactPhone, "Contact phone");
  }

  public String getId() {
    return id;
  }

  public String getName() {
    return name;
  }

  public String getCity() {
    return city;
  }

  public String getContactPhone() {
    return contactPhone;
  }

  public void registerVehicle(String vehicleId) {
    vehicleIds.add(vehicleId);
  }

  public void registerDriver(String driverId) {
    driverIds.add(driverId);
  }

  public void registerStaff(String staffId) {
    staffIds.add(staffId);
  }

  public void registerServiceOffering(String offeringId) {
    if (!serviceOfferingIds.contains(offeringId)) {
      serviceOfferingIds.add(offeringId);
    }
  }

  public List<String> getVehicleIds() {
    return Collections.unmodifiableList(vehicleIds);
  }

  public List<String> getDriverIds() {
    return Collections.unmodifiableList(driverIds);
  }

  public List<String> getStaffIds() {
    return Collections.unmodifiableList(staffIds);
  }

  public List<String> getServiceOfferingIds() {
    return Collections.unmodifiableList(serviceOfferingIds);
  }

  @Override
  public String toString() {
    return name + " (" + city + ")";
  }
}
